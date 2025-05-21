--[[
Name: Wsd-Behind-1.0
Revision: $Rev: 10001 $
Author(s): 树先生 (xhwsd@qq.com)
Website: https://github.com/xhwsd
Description: 检验是否在背后相关库。
Dependencies: AceLibrary, AceDebug-2.0, AceEvent-2.0, SpellStatus-1.0, SpecialEvents-Movement-2.0
]]

-- 主要版本
local MAJOR_VERSION = "Wsd-Behind-1.0"
-- 次要版本
local MINOR_VERSION = "$Revision: 10001 $"

-- 检验AceLibrary
if not AceLibrary then
	error(MAJOR_VERSION .. " requires AceLibrary")
end

-- 检验版本（本库，单实例）
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then
	return
end

-- 检查依赖库
---@param dependencies table 依赖库名称列表
local function CheckDependency(dependencies)
	for _, value in ipairs(dependencies) do
		if not AceLibrary:HasInstance(value) then
			error(format("%s requires %s to function properly", MAJOR_VERSION, value))
		end
	end
end

CheckDependency({
	-- 调试
	"AceDebug-2.0",
	-- 事件
	"AceEvent-2.0",
	-- 法术状态
	"SpellStatus-1.0",
	-- 移动
	"SpecialEvents-Movement-2.0",
})

-- 法术状态
local SpellStatus = AceLibrary("SpellStatus-1.0")
-- 移动
local Movement = AceLibrary("SpecialEvents-Movement-2.0")

-- BOSS名称
local BOOSS_NAMES = {
    ["克尔苏加德"] = true,
    ["拉格纳罗斯"] = true,
}

-- 背刺法术
local BACKSTAB_SPELLS = {
	["撕碎"] = true,
	["毁灭"] = true,
	["突袭"] = true
}

-- BOSS血量
local BOOS_HEALTH = 100000

-- BOSS重置非背后秒数
local BOOS_SECONDS = 10
-- 其它重置非背后秒数
local OTHER_SECONDS = 3

-- 检验猫德是否在背后相关库。
---@class Wsd-Behind-1.0
local Library = {}

-- 库激活
---@param self table 库自身对象
---@param oldLib table 旧版库对象
---@param oldDeactivate function 旧版库停用函数
local function activate(self, oldLib, oldDeactivate)
	-- 新版本使用
	Library = self

	-- 旧版本释放
	if oldLib then
		-- 注销所有事件
		oldLib:UnregisterAllEvents()
		-- 取消所有延时事件
		oldLib:CancelAllScheduledEvents()
	end

	-- 新版本初始化

	-- 背后状态；可选值：pending, yes, no
	self.status = "pending"

	-- 旧版本停用
	if oldDeactivate then
		oldDeactivate(oldLib)
	end
end

-- 外部库加载
---@param self table 库自身对象
---@param major string 外部库主版本
---@param instance table 外部库实例
local function external(self, major, instance)
	if major == "AceDebug-2.0" then
		-- 混入调试
		instance:embed(self)
		-- 开启调试
		self:SetDebugging(true)
		-- 调试等级
		self:SetDebugLevel(3)
	elseif major == "AceEvent-2.0" then
		-- 混入事件
		instance:embed(self)
		-- 注册施法瞬间事件
		self:RegisterEvent("SpellStatus_SpellCastInstant")
		-- 注册施法失败事件
		self:RegisterEvent("SpellStatus_SpellCastFailure")
		-- 注册玩家移动事件
		self:RegisterEvent("SpecialEvents_PlayerMoving")
		-- 注册玩家静止事件
		self:RegisterEvent("SpecialEvents_PlayerStationary")
	end
end

--------------------------------

-- 施法瞬间
---@param id number 法术标识
---@param name string 法术名称
---@param rank number 法术等级
---@param fullName string 法术全名
function Library:SpellStatus_SpellCastInstant(id, name, rank, fullName)
	-- self:LevelDebug(3, "施法瞬间；法术名称：%s；背刺状态：%s", name, self.backstab)

	-- 成功使用背刺法术
	if BACKSTAB_SPELLS[name] then
		self.status = "yes"
	end
end

-- 施法失败
---@param sId number 法术标识
---@param sName string 法术名称
---@param sRank number 法术等级
---@param sFullName string 法术全名
---@param isActiveSpell boolean 是否为当前法术
---@param UIEM_Message string 错误信息
---@param CMSFLP_SpellName string 战斗日志法术名称（CHAT_MSG_SPELL_FAILED_LOCALPLAYER）
---@param CMSFLP_Message string 战斗日志信息（CHAT_MSG_SPELL_FAILED_LOCALPLAYER）
function Library:SpellStatus_SpellCastFailure(sId, sName, sRank, sFullName, isActiveSpell, UIEM_Message, CMSFLP_SpellName, CMSFLP_Message)
	-- self:LevelDebug(3, "施法失败；法术名称：%s；错误提示：%s；背刺状态：%s", sName, UIEM_Message, self.backstab)

	if UIEM_Message and string.find("你必须位于目标背后|距离太远。|你必须面对目标", UIEM_Message) then
		-- 取消已有延迟事件
		if self:IsEventScheduled("Behind_ResetStatus") then
			self:CancelScheduledEvent("Behind_ResetStatus")
		end

		-- 安排延迟事件
		if self:IsBoss() then
			self:ScheduleEvent("Behind_ResetStatus", self.Behind_ResetStatus, BOOS_SECONDS, self)
		else
			self:ScheduleEvent("Behind_ResetStatus", self.Behind_ResetStatus, OTHER_SECONDS, self)
		end

		-- 非背后
		self.status = "no"
	end
end

-- 玩家移动
function Library:SpecialEvents_PlayerMoving()
	-- self:LevelDebug(3, "玩家移动；背后状态：%s", self.status)
	self.status = "pending"
end

-- 玩家静止
function Library:SpecialEvents_PlayerStationary()
	-- self:LevelDebug(3, "玩家静止；背后状态：%s", self.status)
	self.status = "pending"
end

-- 重置状态
function Library:Behind_ResetStatus()
	-- self:LevelDebug(3, "刷重置状态；背后状态：%s", self.status)
	-- 转为待定状态
	if self.status == "no" then
		self.status = "pending"
	end
end

-- 取当前状态
---@return string status 当前状态
function Library:GetStatus()
	return self.status
end

-- 是否在目标背后
---@return boolean can 能否返回真，否则返回假
function Library:IsBehind()
	-- 无目标单位
	if not UnitExists("target") then
		return false
	end

	-- 不在10码内	
	if not CheckInteractDistance("target", 3) then
		return false
	end

	-- 目标的目标是自己（目标正面向自己）
	if UnitIsUnit("targettarget", "player") then
		return false
	end

	-- 已安装UnitXP模组
	if UnitXP then
		-- 与目标近战距离
		---@diagnostic disable-next-line
		if UnitXP("distanceBetween", "player", "target", "meleeAutoAttack") > 0 then
			return false
		end

		-- 是否在目标背后
		---@diagnostic disable-next-line
		return UnitXP("behind", "player", "target")
	end

	-- 无法背刺
	if self.status == "no" then
		return false
	end

	-- 尝试背刺
	return true
end

-- 检验单位是否是BOSS
---@param unit? string 单位名称；缺省为`target`
---@return boolean is 是否是BOSS
function Library:IsBoss(unit)
	unit = unit or "target"

    -- 检查分类
	local class = UnitClassification(unit)
    if class == "worldboss" or class == "rareelite" then
        return true
    end
    
    -- 检查血量（普通BOSS通常血量远高于玩家）
    local health = UnitHealthMax(unit)
    if health > BOOS_HEALTH then
        return true
    end
 
    -- 检查名字
	local name = UnitName(unit)
    if BOOSS_NAMES[name] then
        return true
    end

    return false
end


--------------------------------

-- 最终注册库
AceLibrary:Register(Library, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
---@diagnostic disable-next-line
Library = nil