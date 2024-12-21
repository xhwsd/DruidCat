-- 非德鲁伊退出运行
local _, playerClass = UnitClass("player")
if playerClass ~= "DRUID" then
	return
end

-- 定义插件
DaruidCat = AceLibrary("AceAddon-2.0"):new(
	-- 控制台
	"AceConsole-2.0",
	-- 调试
	"AceDebug-2.0"
)

-- 标签
local DaruidCatTooltip = CreateFrame("GameTooltip", "DaruidCatTooltip", nil, "GameTooltipTemplate")

-- 位与数组
-- @param table array 数组(索引表）
-- @param string|number data 数据
-- @return number 成功返回索引，失败返回nil
local function InArray(array, data)
	if type(array) == "table" then
		for index, value in ipairs(array) do
			if value == data then
				return index
			end
		end
	end
end

-- 自动攻击
local function AutoAttack()
	if not PlayerFrame.inCombat then
		CastSpellByName("攻击")
	end
end

-- 取生命损失
-- @param string unit = "player" 单位
-- @return number 生命损失百分比
-- @return number 生命损失
local function HealthLose(unit)
	unit = unit or "player"

	local max = UnitHealthMax(unit)
	local lose = max - UnitHealth(unit)
	-- 百分比 = 部分 / 整体 * 100
	return math.floor(lose / max * 100), lose
end

-- 取生命剩余
-- @param string unit = "player" 单位
-- @return number 生命剩余百分比
-- @return number 生命剩余
local function HealthResidual(unit)
	unit = unit or "player"

	local residual = UnitHealth(unit)
	-- 百分比 = 部分 / 整体 * 100
	return math.floor(residual / UnitHealthMax(unit) * 100), residual
end

-- 查询效果；查询单位指定效果是否存在
-- @param string buff 效果名称
-- @param string unit = "player" 目标单位；额外还支持`mainhand`、`offhand`
-- @return string|nil 效果类型；可选值：`mainhand`、`offhand`、`buff`、`debuff`
-- @return number 效果索引；从1开始
local function FindBuff(buff, unit)
	unit = unit or "player"
	if not buff then return false end

	-- 适配单位
	DaruidCatTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	if string.lower(unit) == "mainhand" then
		-- 主手
		DaruidCatTooltip:ClearLines()
		DaruidCatTooltip:SetInventoryItem("player", GetInventorySlotInfo("MainHandSlot"));
		for index = 1, DaruidCatTooltip:NumLines() do
			if string.find((getglobal("DaruidCatTooltipTextLeft" .. index):GetText() or ""), buff) then
				return "mainhand", index
			end
		end
	elseif string.lower(unit) == "offhand" then
		-- 副手
		DaruidCatTooltip:ClearLines()
		DaruidCatTooltip:SetInventoryItem("player", GetInventorySlotInfo("SecondaryHandSlot"))
		for index = 1, DaruidCatTooltip:NumLines() do
			if string.find((getglobal("DaruidCatTooltipTextLeft" .. index):GetText() or ""), buff) then
				return "offhand", index
			end
		end
	else
		-- 增益
		local index = 1
		while UnitBuff(unit, index) do 
			DaruidCatTooltip:ClearLines()
			DaruidCatTooltip:SetUnitBuff(unit, index)
			if string.find(DaruidCatTooltipTextLeft1:GetText() or "", buff) then
				return "buff", index
			end
			index = index + 1
		end

		-- 减益
		local index = 1
		while UnitDebuff(unit, index) do
			DaruidCatTooltip:ClearLines()
			DaruidCatTooltip:SetUnitDebuff(unit, index)
			if string.find(DaruidCatTooltipTextLeft1:GetText() or "", buff) then
				return "debuff", index
			end
			index = index + 1
		end
	end
end

-- 法术就绪；检验法术的冷却时间是否结束
-- @param string spell 法术名称
-- @return boolean 已就绪返回true，否则返回false
local function SpellReady(spell)
	if not spell then return false end

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
			return GetSpellCooldown(index, "spell") == 0
		end

		-- 索引递增
		index = index + 1
	end
	return false    
end

-- 检验单位能否流血
-- @param string unit = "target" 单位名称
-- @return boolean 能流血返回true，否则返回false
local function CanBleed(unit)
	unit = unit or "target"
	local creature = UnitCreatureType(unit) or "其它"
	local position = string.find("野兽,小动物,恶魔,龙类,巨人,人型生物,未指定", creature)
	return position ~= nil
end

-- 插件载入
function DaruidCat:OnInitialize()
	-- 精简标题
	self.title = "猫德辅助"
	-- 开启调试
	self:SetDebugging(true)
	-- 调试等级
	self:SetDebugLevel(2)
end

-- 插件打开
function DaruidCat:OnEnable()
	self:LevelDebug(3, "插件打开")

	-- 注册命令
	self:RegisterChatCommand({"/MDFZ", '/DaruidCat'}, {
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

-- 插件关闭
function DaruidCat:OnDisable()
	self:LevelDebug(3, "插件关闭")
end

-- 背刺
function DaruidCat:BackStab()
	-- 潜行
	if FindBuff("潜行") then
		CastSpellByName("毁灭")
	else
		-- 自动攻击
		AutoAttack()
		
		if GetComboPoints("target") == 5 then
			-- 泄连击
			self:Termination()
		elseif FindBuff("节能施法") then
			-- 节能
			if not FindBuff("扫击", "target") and CanBleed("target") then
				-- 流血
				CastSpellByName("扫击")
			elseif not FindBuff("猛虎之怒") then
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

-- 攒点
function DaruidCat:AccumulatePoint()
	-- 自动攻击
	AutoAttack()

	if GetComboPoints("target") == 5 then
		-- 泄连击
		self:Termination()
	elseif FindBuff("节能施法") then
		-- 节能
		if not FindBuff("扫击", "target") and CanBleed("target") then
			-- 流血
			CastSpellByName("扫击")
		elseif not FindBuff("猛虎之怒") then
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

-- 终结
function DaruidCat:Termination()
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
