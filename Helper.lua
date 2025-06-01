if not DruidCat then
	return
end

-- 套装列表
local SUIT_LIST = {
	-- 1.头盔 3.护肩 5.衣服 7.裤子 8.鞋子 18.圣物
	["起源套甲"] = {
		["起源皮盔"] = 1,
		["起源肩垫"] = 3,
		["起源长袍"] = 5,
		["起源短裤"] = 7,
		["起源便靴"] = 8
	}
}

-- 定义辅助对象
local Helper = {}

-- 德鲁伊法力库
local DruidManaLib = AceLibrary("DruidManaLib-1.0")
---@type Wsd-Buff-1.0
local Buff = AceLibrary("Wsd-Buff-1.0")

-- 切换形态；非指定形态取消，无形态转为形态
---@param index number 形态索引；可选值：1.熊、2.豚、3.猫、4.鹿
---@return boolean success 成功返回真，否则返回假
function Helper:SwitchForm(index)
	if self:GetForm() == index then
		return true
	else
		CastShapeshiftForm(index)
		return self:GetForm() == index
	end
end

-- 取当前形态
---@return number|nil current 已变形返回形态索引（1.熊、2.豚、3.猫、4.鹿），未变形返回`nil`
function Helper:GetForm()
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

-- 是否为猫形态
---@return boolean is 是否
function Helper:IsCat()
	local _, _, active = GetShapeshiftFormInfo(3)
	return active == 1
end

-- 取当前剩余法力值
---@return number mana 当前法力值
function Helper:GetMana()
	if SUPERWOW_VERSION then
		-- 优先使用 SuperWow 取法力值
		local _, mana = UnitMana('player')
		---@diagnostic disable-next-line
		return mana
	else
		-- DruidManaLib 不精确
		return DruidManaLib:GetMana()
	end
end

-- 取变形恢复能量数
---@param attach? number 附加能量数；缺省为`0`
---@return number energys 恢复能量数
function Helper:GetMetamorphicRecovery(attach)
	attach = attach or 0

	-- 激怒天赋点数（0/5）
	local _, _, _, _, points = GetTalentInfo(3, 2)
	-- 每点天赋数恢复8点能量（40 = 5 x 8）
	local energys = points * 8

	-- 头盔装备槽标识为1，狼心附魔标识为3004
	local link = GetInventoryItemLink("player", 1)
	if link and self:ItemLinkEnchantID(link) == 3004 then
		-- 变形恢复20点能量
		energys = energys + 20
	end
	return energys + attach
end

-- 项目链接到附魔标识
---@param link string 物品链接
---@return number|nil id 附魔标识
function Helper:ItemLinkEnchantID(link)
	if type(link) == "number" then
		return link
	elseif type(link) == "string" then
		local _, _, id = string.find(link, "item:%d+:(%d+):%d+:%d+")
		if id then
			return tonumber(id)
		end
	end
end

-- 取法术消耗能量数
---@param skill string 法术名称；可选值：`撕碎`、`爪击`、`扫击`
---@param attach? number 附加能量数；缺省为`0`
---@return number energys 消耗能量数
function Helper:GetSpellConsume(skill, attach)
	attach = attach or 0
	local energys = 0
	if skill == "撕碎" then
		energys = 60
		-- 强化撕碎天赋点数（0/2）
		local _, _, _, _, points = GetTalentInfo(2, 10)
		-- 每点天赋减6点能量（12 = 2 x 6）
		energys = energys - 6 * points

		-- 起源套甲（3/5）
		if self:GetSuitCount("起源套甲") >= 3 then
			-- 减3点能量
			energys = energys - 3
		end
	elseif skill == "爪击" then
		energys = 45

		-- 凶暴天赋点数（0/5）
		local _, _, _, _, points = GetTalentInfo(2, 1)
		-- 每点天赋减1点能量（共5点）
		energys = energys - points

		-- 起源套甲（3/5）
		if self:GetSuitCount("起源套甲") >= 3 then
			-- 减3点能量
			energys = energys - 3
		end
		
		-- 凶猛神像
		if self:GetRelicName() == "凶猛神像" then
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
		if self:GetSuitCount("起源套甲") >= 3 then
			-- 减3点能量
			energys = energys - 3
		end

		-- 凶猛神像
		if self:GetRelicName() == "凶猛神像" then
			-- 减3点能量
			energys = energys - 3
		end
	end
	return energys + attach
end

-- 取套装计数
---@param suit string 套装名称；可选值：`起源套甲`
---@param attach? number 附加能量数；缺省为`0`
---@return number count 套装计数
function Helper:GetSuitCount(suit, attach)
	attach = attach or 0

	local count = 0
	if SUIT_LIST[suit] then
		for name, id in pairs(SUIT_LIST[suit]) do
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
function Helper:GetRelicName()
	-- 18为圣物的装备栏位标识
	local link = GetInventoryItemLink("player", 18)
	return link and ItemLinkToName(link) or ""
end

-- 检验单位能否施加减益
---@param debuff string 减益名称
---@param unit? string 目标单位；缺省为`target`
---@return boolean can 可否施法
function Helper:CanDebuff(debuff, unit)
	unit = unit or "target"
	
	if Cursive then
		-- 有Cursive插件
		-- 返回值`guid`来源`SuperWoW`模组
		local _, guid = UnitExists(unit)
		return Cursive.curses:HasCurse(debuff, guid) ~= true
	else
		-- 仅在确定没debuff时，可施放
		return not Buff:FindUnit(debuff, unit)
	end
end

-- 检验单位是否具有减益
---@param debuff string 减益名称
---@param unit? string 目标单位；缺省为`target`
---@return boolean has 是否具有
function Helper:HasDebuff(debuff, unit)
	unit = unit or "target"

	if Cursive then
		-- 有Cursive插件
		-- 返回值`guid`来源`SuperWoW`模组
		local _, guid = UnitExists(unit)
		return Cursive.curses:HasCurse(debuff, guid) == true
	else
		return Buff:FindUnit(debuff, unit) ~= nil
	end
end

-- 检验饰品是否可用
---@param slot number 装备栏位；`13`为饰品1，`14`为饰品2
---@return boolean used 可否使用
function Helper:CanJewelry(slot)
	local start, _, enable = GetInventoryItemCooldown("player", slot)
	return start == 0 and enable == 1
end

-- 开启近战自动攻击
function Helper:AutoAttack()
	if not PlayerFrame.inCombat then
		CastSpellByName("攻击")
	end
end

-- 将辅助注入到插件中
DruidCat.helper = Helper