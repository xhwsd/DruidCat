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
	"AceEvent-2.0",
	-- 数据库
	"AceDB-2.0", 
	-- 小地图菜单
	"FuBarPlugin-2.0"
)

-- 提示
local Tablet = AceLibrary("Tablet-2.0")
-- 法术状态
local SpellStatus = AceLibrary("SpellStatus-1.0")
-- 德鲁伊法力库
local DruidManaLib = AceLibrary("DruidManaLib-1.0")

---@type Wsd-Array-1.0
local Array = AceLibrary("Wsd-Array-1.0")
---@type Wsd-Health-1.0
local Health = AceLibrary("Wsd-Health-1.0")
---@type Wsd-Prompt-1.0
local Prompt = AceLibrary("Wsd-Prompt-1.0")
---@type Wsd-Buff-1.0
local Buff = AceLibrary("Wsd-Buff-1.0")
---@type Wsd-Spell-1.0
local Spell = AceLibrary("Wsd-Spell-1.0")

-- 初始猛虎之怒时间
local tigerFuryTimer = GetTime() - 18
-- 初始撕扯时间
local ripTimer = GetTime() - 12

-- 取法力值
---@return integer currentMana 当前法力值
---@return integer maxMana 法力上限
local function GetMana()
	return DruidManaLib:GetMana()
end

-- 项目链接到附魔标识
---@param link string 物品链接
---@return integer|nil id 附魔标识
local function ItemLinkEnchantID(link)
	if type(link) == "number" then
		return link
	elseif type(link) == "string" then
		local _, _, id = string.find(link, "item:%d+:(%d+):%d+:%d+")
		if id then
			return tonumber(id)
		end
	end
end

-- 取套装计数
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

-- 取圣物名称
---@return string name 圣物名称；无圣物返回空字符串
local function GetRelicName()
	-- 18为圣物的装备栏位标识
	local link = GetInventoryItemLink("player", 18)
	return link and ItemLinkToName(link) or ""
end

-- 是否为猫形态
---@return boolean is 是否
local function IsCat()
	local _, _, active = GetShapeshiftFormInfo(3)
	return active == 1
end

-- 取当前形态
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

-- 切换形态；非指定形态取消，无形态转为形态
---@param index integer 形态索引；可选值：1.熊、2.豚、3.猫、4.鹿
---@return boolean success 成功返回真，否则返回假
local function SwitchForm(index)
	local current = GetCurrentForm()
	if not current then
		-- 转为指定形态
		CastShapeshiftForm(index)
		return true
	elseif current ~= index then
		-- 取消非指定形态
		CastShapeshiftForm(current)
		return true
	end
end

-- 取变形恢复能量数
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

-- 取技能消耗能量数
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
		-- 每点天赋减1点能量（共5点）
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
		-- 每点天赋减1点能量（共5点）
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

-- 检验单位能否流血
---@param unit? string 单位名称；缺省为`target`
---@return boolean can 能流血返回真，否则返回假
local function CanBleed(unit)
	unit = unit or "target"
	local creature = UnitCreatureType(unit) or "其它"
	local position = string.find("野兽,小动物,恶魔,龙类,巨人,人型生物,未指定", creature)
	return position ~= nil
end

-- 插件载入
function DruidCat:OnInitialize()
	-- 精简标题
	self.title = "猫德"
	-- 开启调试
	self:SetDebugging(true)
	-- 调试等级
	self:SetDebugLevel(2)

	-- 注册数据
	self:RegisterDB("DruidCatDB")
	-- 注册默认值
	self:RegisterDefaults('profile', {

	})

	-- 具体图标
	self.hasIcon = true
	-- 小地图图标
	self:SetIcon("Interface\\Icons\\Ability_Druid_CatForm")
	-- 默认位置
	self.defaultPosition = "LEFT"
	-- 默认小地图位置
	self.defaultMinimapPosition = 210
	-- 无法分离提示（标签）
	self.cannotDetachTooltip = false
	-- 角色独立配置
	self.independentProfile = true
	-- 挂载时是否隐藏
	self.hideWithoutStandby = false
	-- 注册菜单项
	self.OnMenuRequest = {
		type = "group",
		handler = self,
		args = {}
	}
end

-- 插件打开
function DruidCat:OnEnable()
	self:LevelDebug(3, "插件打开")

	-- 背后状态；可选值：pending, yes, no
	self.behindStatus = "pending"

	-- 释放瞬间
	self:RegisterEvent("SpellStatus_SpellCastInstant")
	-- 释放失败
	self:RegisterEvent("SpellStatus_SpellCastFailure")
end

-- 插件关闭
function DruidCat:OnDisable()
	self:LevelDebug(3, "插件关闭")
end

-- 提示更新
function DruidCat:OnTooltipUpdate()
	-- 置小地图图标点燃提示
	Tablet:SetHint("\n鼠标右键 - 显示插件选项")
end

-- 瞬间施放
function DruidCat:SpellStatus_SpellCastInstant(id, name, rank, fullName)
	self:LevelDebug(3, "瞬间施放；法术全名：%s", fullName)

	if name == "撕碎" or name == "毁灭" then
		self.behindStatus = "yes"
	elseif not name then
		self.behindStatus = "pending"
	end
end

-- 施放失败
function DruidCat:SpellStatus_SpellCastFailure(sId, sName, sRank, sFullName, isActiveSpell, UIEM_Message, CMSFLP_SpellName, CMSFLP_Message)
	self:LevelDebug(3, "施放失败；法术全名：%s；错误提示：%s", sFullName, UIEM_Message)

	if UIEM_Message and string.find("你必须位于目标背后|距离太远。|你必须面对目标", UIEM_Message) then
		self.behindStatus = "no"
	end
end

-- 可否背后
---@return boolean can 能否返回真，否则返回假
function DruidCat:CanBehind()
	-- 无目标单位
	if not UnitExists("target") then
		return false
	end

	-- 不在10码内	
	if not CheckInteractDistance("target", 3) then
		return false
	end

	-- 目标的目标是自己
	if UnitIsUnit("targettarget", "player") then
		return false
	end

	-- 非背后，当施放技能会刷新该状态
	if self.behindStatus == "no" then
		return false
	end

	-- 尝试背后
	return true
end

-- 背刺
function DruidCat:BackStab()
	-- 潜行
	if Buff:GetUnit("潜行") then
		CastSpellByName("毁灭")
	else
		-- 自动攻击
		Spell:AutoAttack()
		
		if GetComboPoints("target") == 5 then
			-- 泄连击
			self:Termination()
		elseif Buff:GetUnit("节能施法") then
			-- 节能
			if CanBleed(unit) and not Buff:GetUnit("扫击", "target") then
				-- 流血
				CastSpellByName("扫击")
			elseif not Buff:GetUnit("猛虎之怒") then
				-- 增益
				CastSpellByName("猛虎之怒")
			else
				-- 泄能量
				CastSpellByName("撕碎")
			end
		elseif Spell:IsReady("精灵之火（野性）") then
			-- 骗节能
			CastSpellByName("精灵之火（野性）")
		else
			-- 泄能量
			CastSpellByName("撕碎")
		end
	end
end

-- 攒点
function DruidCat:AccumulatePoint()
	-- 自动攻击
	Spell:AutoAttack()

	if GetComboPoints("target") == 5 then
		-- 泄连击
		self:Termination()
	elseif Buff:GetUnit("节能施法") then
		-- 节能
		if CanBleed(unit) and not Buff:GetUnit("扫击", "target") then
			-- 流血
			CastSpellByName("扫击")
		elseif not Buff:GetUnit("猛虎之怒") then
			-- 增益
			CastSpellByName("猛虎之怒")
		else
			-- 泄能量
			CastSpellByName("爪击")
		end
	elseif Spell:IsReady("精灵之火（野性）") then
		-- 骗节能
		CastSpellByName("精灵之火（野性）")
	else
		-- 泄能量
		CastSpellByName("爪击")
	end
end

-- 终结
function DruidCat:Termination()
	-- 自动攻击
	Spell:AutoAttack()

	-- 流血策略
	local residual = 40 -- 非普通怪
	if not CanBleed() then
		residual = 0 -- 不可流血怪
	elseif UnitClassification("target") == "normal" then
		residual = 20 -- 普通怪
	end

	-- 使用法术
	local percent = Health:GetRemaining("target")
	if residual > 0 and percent > residual then
		-- 流血
		CastSpellByName("撕扯")
	else
		CastSpellByName("凶猛撕咬")
	end
end

-- 抓挠
---@param cooldownSlot? integer 检验冷却槽位索引；缺省为`20`
function DruidCat:Scratch(cooldownSlot)
	cooldownSlot = cooldownSlot or 20

	-- 切换为猎豹形态

	SwitchForm(3)

	-- 自动攻击
	Spell:AutoAttack()

	--变形恢复能量数
	local metamorphicRecover = GetMetamorphicRecover()

	-- 补猛虎
	if
		-- 为猎豹形态
		IsCat() and
		-- 能量高于变形恢复
		UnitMana("player") >= metamorphicRecover and
		-- 无猛虎之怒效果
		not Buff:GetUnit("猛虎之怒")
	then
		-- 
		CastSpellByName("猛虎之怒")
		tigerFuryTimer = GetTime()
	end

	-- 变形
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

	-- 节能
	if Buff:GetUnit("节能施法") then
		if self:CanBehind() then
			CastSpellByName("撕碎")
		else
			CastSpellByName("爪击")
		end
	elseif not Buff:GetUnit("精灵之火", "target") then
		CastSpellByName("精灵之火（野性）")
	end

	-- 补撕扯
	if GetComboPoints("target") > 0 and not Buff:GetUnit("撕扯", "target") and CanBleed() then
		CastSpellByName("撕扯")
		ripTimer = GetTime()
	elseif GetComboPoints("target") > 3 and UnitMana("player") < 60 and GetTime() - ripTimer < 9 then
		-- 能量低于60
		-- 撕扯剩余3s内就不放凶猛，留星等补撕扯
		CastSpellByName("凶猛撕咬")
	end

	-- T2.5套装效果
	if Buff:GetUnit("强化攻击") then
		-- 取撕碎消耗能量数
		if self:CanBehind() and GetSkillConsume("撕碎") <= 48 then
			-- 60能量撕碎性价比太低
			CastSpellByName("撕碎")
		else
			CastSpellByName("爪击")
		end
	elseif CanBleed() then
		if not Buff:GetUnit("扫击", "target") then
			CastSpellByName("扫击")
		elseif Buff:GetUnit("撕扯", "target") then
			CastSpellByName("爪击")
		end
	else
		CastSpellByName("爪击")
	end

	CastSpellByName("精灵之火（野性）")
	
	-- 凶猛撕咬：终结技，消耗30能量，12秒流血
	-- 撕扯：终结技，消耗35能量，立即伤害
	-- 扫击：奖励连击点，消耗40能量
	-- 撕碎：奖励连击点，消耗60能量，背后发动
	-- 爪击：奖励连击点，消耗45能量
	-- 猛虎之怒：增益，消耗30能量，持续15秒
end

-- 冲锋
function DruidCat:Charge()
	if not Spell:IsReady("野性冲锋") then
		Prompt:Warning("冲锋冷却中")
	end

	local rorm = GetCurrentForm()
	if not rorm then
		-- 人形态
		if GetMana() >= 400 then
			SwitchForm(1)
			CastSpellByName("野性冲锋")
		else
			Prompt:Warning("变形法力不足")
		end
	elseif rorm == 1 then
		-- 熊形态
		if UnitMana("player") < 5 and Spell:IsReady("狂怒") then
			CastSpellByName("狂怒")
		end

		if UnitMana("player") >= 5 then
			CastSpellByName("野性冲锋")
		else
			Prompt:Warning("冲锋怒气不足")
		end
	else
		-- 非熊形态
		if GetMana() >= 800 then
			SwitchForm(1)
			CastSpellByName("野性冲锋")
		else
			Prompt:Warning("变形法力不足")
		end
	end
end

-- 昏迷
function DruidCat:Coma()
	if not Spell:IsReady("重击") then
		Prompt:Warning("重击冷却中")
	end

	local rorm = GetCurrentForm()
	if not rorm then
		-- 人形态
		if GetMana() >= 400 then
			SwitchForm(1)
			CastSpellByName("重击")
		else
			Prompt:Warning("变形法力不足")
		end
	elseif rorm == 1 then
		-- 熊形态
		if UnitMana("player") < 10 and Spell:IsReady("狂怒") then
			CastSpellByName("狂怒")
		end

		if UnitMana("player") >= 10 then
			CastSpellByName("重击")
		else
			Prompt:Warning("重击怒气不足")
		end
	else
		-- 非熊形态
		if GetMana() >= 800 then
			SwitchForm(1)
			CastSpellByName("重击")
		else
			Prompt:Warning("变形法力不足")
		end
	end
end

function DruidCat:Test()
	-- Printd("-- -- -- -- -- -- -- -- -- -- -- -")
	-- Printd("变形恢复能量数：", GetMetamorphicRecover())
	-- Printd("当前形态：", GetCurrentForm())
	-- Printd("是否为猎豹形态：", IsCatForm(3))
	-- Printd("起源套甲套装计数：", GetSuitCount("起源套甲"))
	-- Printd("头盔附魔标识：", ItemLinkEnchantID(GetInventoryItemLink("player", 1)))
	
	-- Printd("圣物名称：", GetRelicName())
	-- Printd("撕碎消耗能量数：", GetSkillConsume("撕碎"))
	-- Printd("爪击消耗能量数：", GetSkillConsume("爪击"))
	-- Printd("扫击消耗能量数：", GetSkillConsume("扫击"))

	self:LevelDebug(3, "测试；背后状态：%s；可否背后：%s", self.behindStatus, self:CanBehind())
	if self:CanBehind() then
		CastSpellByName("撕碎")
	else
		CastSpellByName("爪击")
	end
	
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
