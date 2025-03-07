-- 非德鲁伊退出运行
local _, playerClass = UnitClass("player")
if playerClass ~= "DRUID" then
	return
end

-- 定义插件
DruidCat = AceLibrary("AceAddon-2.0"):new(
	-- 控制台
	"AceConsole-2.0",
	-- 调试
	"AceDebug-2.0",
	-- 事件
	"AceEvent-2.0"
)

-- 德鲁伊法力库
local druidManaLib = AceLibrary("DruidManaLib-1.0")

-- 初始猛虎之怒时间
local tigerFuryTimer = GetTime() - 18
-- 初始撕扯时间
local ripTimer = GetTime() - 12
-- 非背后时间
local notBehindTime = 0

---提示警告
---@param message string 提示信息
---@param... any 可变参数
local function HintWarning(message, ...)
	if arg.n then
		message = string.format(message, unpack(arg))
	end
	UIErrorsFrame:AddMessage(message, 1.0, 1.0, 0.0, 53, 5)
end

---位与数组
---@param array table 数组(索引表）
---@param data any 数据
---@return integer|nil index 成功返回索引，失败返回空
local function InArray(array, data)
	if type(array) == "table" then
		for index, value in ipairs(array) do
			if value == data then
				return index
			end
		end
	end
end

---自动攻击
local function AutoAttack()
	if not PlayerFrame.inCombat then
		CastSpellByName("攻击")
	end
end

---取生命剩余
---@param unit? string 单位；缺省为`player`
---@return integer percentage 生命剩余百分比
---@return integer residual 生命剩余
local function HealthResidual(unit)
	unit = unit or "player"
	local residual = UnitHealth(unit)
	-- 百分比 = 部分 / 整体 * 100
	return math.floor(residual / UnitHealthMax(unit) * 100), residual
end

---法术就绪；检验法术的冷却时间是否结束
---@param spell string 法术名称
---@return boolean ready 已就绪返回真，否则返回假
---@return number cooldown 冷却时间秒数，无冷却时间为`0`
local function SpellReady(spell)
	if not spell then
		return false, 0
	end

	-- 名称到索引
	local index = 1
	while true do
		-- 取法术名称
		local name = GetSpellName(index, BOOKTYPE_SPELL)
		if not name or name == "" or name == "充能点" then
			break
		end

		-- 比对名称
		if name == spell then
			-- 取法术冷却
			local start, duration = GetSpellCooldown(index, "spell")
			return start == 0, duration - (GetTime() - start)
		end

		-- 索引递增
		index = index + 1	
	end
	return false, 0
end

---检验单位能否流血
---@param unit? string 单位名称；缺省为`target`
---@return boolean can 能流血返回真，否则返回假
local function CanBleed(unit)
	unit = unit or "target"
	local creature = UnitCreatureType(unit) or "其它"
	local position = string.find("野兽,小动物,恶魔,龙类,巨人,人型生物,未指定", creature)
	return position ~= nil
end

---检验单位能否扫击
---@param unit? string 单位名称；缺省为`target`
---@return boolean can 能扫击返回真，否则返回假
local function CanRake(unit)
	unit = unit or "target"

	-- 检验流血
	if not CanBleed(unit) then
		return false
	end

	-- 检验减益
	if not UnitHasAura(unit, "扫击") then
		return true
	end
	return false
end

---置动作条法术
---@param slotIndex integer 动作条槽位索引
---@param spellName string 法术名称
local function SetActionSpell(slotIndex, spellName)
	-- text = GetActionText()
	-- type, id = GetActionText()
	-- type, id = GetActionText()
	if GetActionText(slotIndex) ~= spellName then
		PickupSpell(GetSpellIndex(spellName), BOOKTYPE_SPELL)
		PlaceAction(slotIndex)
		ClearCursor()
	end
end

---取法力值
---@return integer currentMana 当前法力值
---@return integer maxMana 法力上限
local function GetMana()
	return druidManaLib:GetMana()
end

---是否为猫形态
---@return boolean isCat 是否为猫
local function IsCatForm()
	local _, _, active = GetShapeshiftFormInfo(3)
	return active == 1
end

---取当前形态
---@return integer|nil current 已变形返回形态索引，未变形返回`nil`
local function GetCurrentForm()
	-- 取当前形态
	local current
	for index = 1, 6 do
		local _, _, active = GetShapeshiftFormInfo(index)
		if active then
			current = index
			break
		end
	end
	return current
end

---切换形态；非指定形态取消，无形态转为形态
---@param index integer 形态索引；可选值：1.熊、2.豚、3.猫、4.鹿
local function SwitchForm(index)
	local current = GetCurrentForm()
	if not current then
		-- 转为指定形态
		CastShapeshiftForm(index)
	elseif current ~= index then
		-- 取消非指定形态
		CastShapeshiftForm(index)
	end
end

---项目链接到附魔标识
---@param link string 物品链接
---@return integer|nil id 附魔标识
function ItemLinkEnchantID(link)
	if type(link) == "number" then
		return link
	elseif type(link) == "string" then
		local _, _, id = string.find(link, "item:%d+:(%d+):%d+:%d+")
		if id then
			return tonumber(id)
		end
	end
end

---取变形恢复能量数
---@param attach? integer 附加能量数；缺省为`0`
---@return integer energys 恢复能量数
local function GetMetamorphicRecover(attach)
	attach = attach or 0
	-- 激怒天赋点数（0/5）
	local _, _, _, _, points = GetTalentInfo(3, 2)
	-- 每点天赋数恢复8点能量（40 = 5 x 8）
	local energys = points * 8

	-- 头盔装备槽标识为1，狼心附魔标识为3004
	local link = GetInventoryItemLink("player", 1)
	if link and ItemLinkEnchantID(link) == 3004 then
		-- 变形恢复20点能量
		energys = energys + 20
	end
	return energys + attach
end

---取套装计数
---@param suit string 套装名称；可选值：`起源套甲`
---@param attach? integer 附加能量数；缺省为`0`
---@return integer count 套装计数
local function GetSuitCount(suit, attach)
	attach = attach or 0

	-- 1.头盔 3.护肩 5.衣服 7.裤子 8.鞋子 18.圣物
	local data = {
		["起源套甲"] = {
			["起源皮盔"] = 1,
			["起源肩垫"] = 3,
			["起源长袍"] = 5,
			["起源短裤"] = 7,
			["起源便靴"] = 8
		}
	}

	local count = 0
	if data[suit] then
		for name, id in pairs(data[suit]) do
			local link = GetInventoryItemLink("player", id)
			if (ItemLinkToName(link) == name) then
				count = count + 1
			end
		end
	end
	return count + attach
end

---取圣物名称
---@return string name 圣物名称；无圣物返回空字符串
local function GetRelicName()
	-- 18为圣物的装备栏位标识
	local link = GetInventoryItemLink("player", 18)
	return link and ItemLinkToName(link) or ""
end

---取技能消耗能量数
---@param skill string 技能名称；可选值：`撕碎`、`爪击`、`扫击`
---@param attach? integer 附加能量数；缺省为`0`
---@return integer energys 消耗能量数
local function GetSkillConsume(skill, attach)
	attach = attach or 0
	local energys = 0
	if skill == "撕碎" then
		energys = 60
		-- 强化撕碎天赋点数（0/2）
		local _, _, _, _, points = GetTalentInfo(2, 10)
		-- 每点天赋减6点能量（12 = 2 x 6）
		energys = energys - 6 * points
	elseif skill == "爪击" then
		energys = 45

		-- 凶暴天赋点数（0/5）
		local _, _, _, _, points = GetTalentInfo(2, 1)
		-- 每点天赋减1点能量（5）
		energys = energys - points

		-- 起源套甲（3/5）
		if GetSuitCount("起源套甲") >= 3 then
			-- 减3点能量
			energys = energys - 3
		end
		
		-- 凶猛神像
		if (GetRelicName() == "凶猛神像") then
			-- 减3点能量
			energys = energys - 3
		end
	elseif skill == "扫击" then
		energys = 40

		-- 凶暴天赋点数（0/5）
		local _, _, _, _, points = GetTalentInfo(2, 1)
		-- 每点天赋减1点能量（5）
		energys = energys - points

		-- 起源套甲（3/5）
		if GetSuitCount("起源套甲") >= 3 then
			-- 减3点能量
			energys = energys - 3
		end

		-- 凶猛神像
		if (GetRelicName() == "凶猛神像") then
			-- 减3点能量
			energys = energys - 3
		end
	end
	return energys + attach
end

---插件载入
function DruidCat:OnInitialize()
	-- 精简标题
	self.title = "猫德辅助"
	-- 开启调试
	self:SetDebugging(true)
	-- 调试等级
	self:SetDebugLevel(2)
end

---插件打开
function DruidCat:OnEnable()
	self:LevelDebug(3, "插件打开")

	-- 注册事件
	self:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
	self:RegisterEvent("CHAT_MSG_SPELL_FAILED_LOCALPLAYER")

	-- 注册命令
	self:RegisterChatCommand({"/MDFZ", '/DruidCat'}, {
		type = "group",
		args = {
			tsms = {
				name = "调试模式",
				desc = "开启或关闭调试模式",
				type = "toggle",
				get = "IsDebugging",
				set = "SetDebugging"
			},
			tsdj = {
				name = "调试等级",
				desc = "设置或获取调试等级",
				type = "range",
				min = 1,
				max = 3,
				get = "GetDebugLevel",
				set = "SetDebugLevel"
			}
		},
	})
end

---插件关闭
function DruidCat:OnDisable()
	self:LevelDebug(3, "插件关闭")
end

function DruidCat:CHAT_MSG_SPELL_SELF_DAMAGE()
	self:LevelDebug(3, "CHAT_MSG_SPELL_SELF_DAMAGE；消息：%s", arg1)
	-- 你的(.+)对(.+)造成(\d+)致命一击伤害。
	-- 你的(.+)中(.+)造成(\d+)点伤害。
	-- 你的(.+)被(.+)躲闪过去
	if string.find(arg1, "撕碎") then
		notBehindTime = 0
	end
end

function DruidCat:CHAT_MSG_SPELL_FAILED_LOCALPLAYER()
	self:LevelDebug(3, "CHAT_MSG_SPELL_FAILED_LOCALPLAYER；消息：%s", arg1)
	local spell, reason = string.match(arg1, "你施展(.+)失败：(.+)")
	if spell == "撕碎" then
		notBehindTime = string.find("你必须位于目标背后,超出范围,你必须面对目标", reason) and GetTime() or 0
	end
end

--- 可否撕碎
---@param expired? number 非背后过期秒数；缺省为`3`
---@return boolean can 能否返回真，否则返回假
function DruidCat:CanRip(expired)
	expired = expired or 3
	return notBehindTime == 0 or GetTime() - notBehindTime >= expired
end

---背刺
function DruidCat:BackStab()
	-- 潜行
	if MyBuff("潜行") then
		CastSpellByName("毁灭")
	else
		-- 自动攻击
		AutoAttack()
		
		if GetComboPoints("target") == 5 then
			-- 泄连击
			self:Termination()
		elseif MyBuff("节能施法") then
			-- 节能
			if CanRake("target") then
				-- 流血
				CastSpellByName("扫击")
			elseif not MyBuff("猛虎之怒") then
				-- 增益
				CastSpellByName("猛虎之怒")
			else
				-- 泄能量
				CastSpellByName("撕碎")
			end
		elseif SpellReady("精灵之火（野性）") then
			-- 骗节能
			CastSpellByName("精灵之火（野性）")
		else
			-- 泄能量
			CastSpellByName("撕碎")
		end
	end
end

---攒点
function DruidCat:AccumulatePoint()
	-- 自动攻击
	AutoAttack()

	if GetComboPoints("target") == 5 then
		-- 泄连击
		self:Termination()
	elseif MyBuff("节能施法") then
		-- 节能
		if CanRake("target") then
			-- 流血
			CastSpellByName("扫击")
		elseif not MyBuff("猛虎之怒") then
			-- 增益
			CastSpellByName("猛虎之怒")
		else
			-- 泄能量
			CastSpellByName("爪击")
		end
	elseif SpellReady("精灵之火（野性）") then
		-- 骗节能
		CastSpellByName("精灵之火（野性）")
	else
		-- 泄能量
		CastSpellByName("爪击")
	end
end

---终结
function DruidCat:Termination()
	-- 自动攻击
	AutoAttack()

	-- 流血策略
	local residual = 40 -- 非普通怪
	if not CanBleed("target") then
		residual = 0 -- 不可流血怪
	elseif UnitClassification("target") == "normal" then
		residual = 20 -- 普通怪
	end

	-- 使用法术
	local percent = HealthResidual("target")
	if residual > 0 and percent > residual then
		-- 流血
		CastSpellByName("撕扯")
	else
		CastSpellByName("凶猛撕咬")
	end
end

---抓挠
---@param cooldownSlot? integer 检验冷却槽位索引；缺省为`20`
function DruidCat:Scratch(cooldownSlot)
	cooldownSlot = cooldownSlot or 20

	-- 切换为猎豹形态
	SwitchForm(3)

	-- 自动攻击
	AutoAttack()

	--变形恢复能量数
	local metamorphicRecover = GetMetamorphicRecover()

	if
		-- 为猎豹形态
		IsCatForm() and
		-- 当前能量足够
		UnitMana("player") >= metamorphicRecover and
		-- 无猛虎之怒效果
		not MyBuff("猛虎之怒")
	then
		-- 补猛虎之怒
		CastSpellByName("猛虎之怒")
		tigerFuryTimer = GetTime()
	end

	if
		-- 公共冷却小于0.05
		GetActionCooldown(cooldownSlot) < 0.05 and
		(
			-- 当前能量不足爪击，24是2s回能20点加上流血回能4点
			UnitMana("player") < GetSkillConsume("爪击") - 24 or
			(
				-- 与补猛虎之怒间隔10秒
				GetTime() - tigerFuryTimer > 10 and
				-- 当前能量低于扫击消耗
				UnitMana("player") < GetSkillConsume("扫击")
			)
		) and
		-- 可恢复40能量
		metamorphicRecover >= 40 and
		-- 法术足够变形（猎豹形态需要348法力，因取法力值不精确这里约2个变形法力值）
		GetMana() >= 600
	then
		-- 取消猎豹形态
		CastSpellByName("猎豹形态")
	end

	if MyBuff("节能施法") then
		if self:CanRip() then
			CastSpellByName("撕碎")
		else
			CastSpellByName("爪击")
		end
	elseif not UnitHasAura("target", "精灵之火") then
		CastSpellByName("精灵之火（野性）")
	end

	-- 补撕扯
	if GetComboPoints("target") > 0 and not UnitHasAura("target", "撕扯") and CanBleed("target") then
		CastSpellByName("撕扯")
		ripTimer = GetTime()
	elseif GetComboPoints("target") > 3 and UnitMana("player") < 60 and GetTime() - ripTimer < 9 then
		-- 能量低于60
		-- 撕扯剩余3s内就不放凶猛，留星等补撕扯
		CastSpellByName("凶猛撕咬")
	end

	-- T2.5套装效果
	if MyBuff("强化攻击") then
		-- 取撕碎消耗能量数
		if self:CanRip() and GetSkillConsume("撕碎") <= 48 then
			-- 60能量撕碎性价比太低
			CastSpellByName("撕碎")
		else
			CastSpellByName("爪击")
		end
	elseif CanBleed("target") then
		if not UnitHasAura("target", "扫击") then
			CastSpellByName("扫击")
		elseif UnitHasAura("target", "扫击") and UnitHasAura("target", "撕扯") then
			CastSpellByName("爪击")
		end
	else
		CastSpellByName("爪击")
	end

	CastSpellByName("精灵之火（野性）")

	-- Sound_EnableErrorSpeech 1
	-- UIErrorsFrame:Clear()
end

---冲锋
function DruidCat:Charge()
	if not SpellReady("野性冲锋") then
		HintWarning("冲锋冷却中...")
	end

	local rorm = GetCurrentForm()
	if not rorm then
		-- 人形态
		if GetMana() >= 400 then
			SwitchForm(1)
			CastSpellByName("野性冲锋")
		else
			HintWarning("变形法力不足...")
		end
	elseif rorm == 1 then
		-- 熊形态
		if UnitMana("player") < 5 and SpellReady("狂怒") then
			CastSpellByName("狂怒")
		end

		if UnitMana("player") >= 5 then
			CastSpellByName("野性冲锋")
		else
			HintWarning("冲锋怒气不足...")
		end
	else
		-- 非熊形态
		if GetMana() >= 800 then
			SwitchForm(1)
			CastSpellByName("野性冲锋")
		else
			HintWarning("变形法力不足...")
		end
	end
end

---昏迷
function DruidCat:Coma()
	if not SpellReady("重击") then
		HintWarning("重击冷却中...")
	end

	local rorm = GetCurrentForm()
	if not rorm then
		-- 人形态
		if GetMana() >= 400 then
			SwitchForm(1)
			CastSpellByName("重击")
		else
			HintWarning("变形法力不足...")
		end
	elseif rorm == 1 then
		-- 熊形态
		if UnitMana("player") < 10 and SpellReady("狂怒") then
			CastSpellByName("狂怒")
		end

		if UnitMana("player") >= 10 then
			CastSpellByName("重击")
		else
			HintWarning("重击怒气不足...")
		end
	else
		-- 非熊形态
		if GetMana() >= 800 then
			SwitchForm(1)
			CastSpellByName("重击")
		else
			HintWarning("变形法力不足...")
		end
	end
end

function DruidCat:Test()
	Printd("----------------------------------")
	Printd("变形恢复能量数：", GetMetamorphicRecover())
	Printd("当前形态：", GetCurrentForm())
	Printd("是否为猎豹形态：", IsCatForm())
	Printd("起源套甲套装计数：", GetSuitCount("起源套甲"))
	Printd("头盔附魔标识：", ItemLinkEnchantID(GetInventoryItemLink("player", 1)))
	
	Printd("圣物名称：", GetRelicName())
	Printd("撕碎消耗能量数：", GetSkillConsume("撕碎"))
	Printd("爪击消耗能量数：", GetSkillConsume("爪击"))
	Printd("扫击消耗能量数：", GetSkillConsume("扫击"))
end

-- 猎豹形态：348法力
-- 猛虎之怒：30能量，1秒冷却；持续18秒提高伤害
-- 节能施法：触发增益；下一个攻击技能免能量消耗
-- 精灵之火（野性）：6秒冷却；持续40秒降低护甲
-- 爪击：34能量；立即伤害，奖励1个连击点
-- 撕碎：48能量；背刺立即伤害，奖励1个连击点
-- 扫击：29能量；立即伤害和9秒持续伤害，奖励1个连击点
-- 撕扯：30能量；终结技，持续12秒伤害
-- 凶猛撕咬：35能量；终结技，立即伤害
