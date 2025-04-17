--[[
Name: Wsd-Bleed-1.0
Revision: $Rev: 10001 $
Author(s): 树先生 (xhwsd@qq.com)
Website: https://github.com/xhwsd
Description: 检验可否流血相关库。
Dependencies: AceLibrary
]]

-- 主要版本
local MAJOR_VERSION = "Wsd-Bleed-1.0"
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

-- 名称黑名单
local BLACKLIST_NAMES = {
	
}

-- 名称白名单
local WHITELIST_NAMEE = {
	["野兽"] = true,
	["小动物"] = true,
	["恶魔"] = true,
	["龙类"] = true,
	["巨人"] = true,
	["人型生物"] = true,
	["未指定"] = true
}

-- 生物黑名单
local BLACKLIST_CREATURES = {
	
}

-- 生物白名单
local WHITELIST_CREATURE = {
	["野兽"] = true,
	["小动物"] = true,
	["恶魔"] = true,
	["龙类"] = true,
	["巨人"] = true,
	["人型生物"] = true,
	["未指定"] = true
}

-- 数组相关库。
---@class Wsd-Array-1.0
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
		-- ...
	end

	-- 新版本初始化
	-- ...

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

end

--------------------------------

-- 检验单位能否流血
---@param unit? string 单位名称；缺省为`target`
---@return boolean can 能流血返回真，否则返回假
function Library:Can(unit)
	unit = unit or "target"
	local creature = UnitCreatureType(unit)
	if not creature then
		return false
	end

	-- 不可流血
	if BLEED_BLACKLIST[creature] then
		return false
	end

	-- 可以流血
	if BLEED_WHITELIST[creature] then
		return true
	end
	
	-- 其他返回假，防止无限上流血而免疫
	return false
end

--------------------------------

-- 最终注册库
AceLibrary:Register(Library, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
---@diagnostic disable-next-line: cast-local-type
Library = nil