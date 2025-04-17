--[[
Name: Wsd-Behind-1.0
Revision: $Rev: 10001 $
Author(s): 树先生 (xhwsd@qq.com)
Website: https://github.com/xhwsd
Description: 检验是否在背后相关库。
Dependencies: AceLibrary, AceDebug-2.0, AceEvent-2.0, SpellStatus-1.0
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
	"SpellStatus-1.0"
})

-- 法术状态
local SpellStatus = AceLibrary("SpellStatus-1.0")

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
		-- 注册瞬间施法事件
		self:RegisterEvent("SpellStatus_SpellCastInstant")
		-- 注册施法失败事件
		self:RegisterEvent("SpellStatus_SpellCastFailure")
	end
end

--------------------------------

-- 瞬间施法
function Library:SpellStatus_SpellCastInstant(id, name, rank, fullName)
	self:LevelDebug(3, "瞬间施法；法术全名：%s", fullName)

	if name == "撕碎" or name == "毁灭" then
		self.status = "yes"
	elseif not name then
		self.status = "pending"
	end
end

-- 施法失败
function Library:SpellStatus_SpellCastFailure(sId, sName, sRank, sFullName, isActiveSpell, UIEM_Message, CMSFLP_SpellName, CMSFLP_Message)
	self:LevelDebug(3, "施法失败；法术全名：%s；错误提示：%s", sFullName, UIEM_Message)

	if UIEM_Message and string.find("你必须位于目标背后|距离太远。|你必须面对目标", UIEM_Message) then
		self.status = "no"
	end
end

-- 可否背后
---@return boolean can 能否返回真，否则返回假
function Library:Can()
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
	if self.status == "no" then
		return false
	end

	-- 尝试背后
	return true
end

--------------------------------

-- 最终注册库
AceLibrary:Register(Library, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
---@diagnostic disable-next-line: cast-local-type
Library = nil