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
-- 移动
local Movement = AceLibrary("SpecialEvents-Movement-2.0")

---@type Wsd-Behind-1.0
local Behind = AceLibrary("Wsd-Behind-1.0")
---@type Wsd-Bleed-1.0
local Bleed = AceLibrary("Wsd-Bleed-1.0")
---@type Wsd-Buff-1.0
local Buff = AceLibrary("Wsd-Buff-1.0")
---@type Wsd-Health-1.0
local Health = AceLibrary("Wsd-Health-1.0")
---@type Wsd-Prompt-1.0
local Prompt = AceLibrary("Wsd-Prompt-1.0")
---@type Wsd-Spell-1.0
local Spell = AceLibrary("Wsd-Spell-1.0")

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
		-- 时机
		timing = {
			-- 斩杀生命
			killHealth = 30,
			-- 能量匮乏
			energyDeficit = 40,
			-- ​能量富裕​​
			energySurplus = 60,
			-- 饰品1
			-- 饰品1
			jewelry1 = {
				-- 有扫击时
				hasRake = true,
				-- 有撕扯时
				hasRip = true,
				-- 是斩杀时
				isKill = false,
				-- 是BOSS时
				isBoss = false,
			},
			-- 饰品2
			jewelry2 = {
				-- 有扫击时
				hasRake = true,
				-- 有撕扯时
				hasRip = true,
				-- 是斩杀时
				isKill = false,
				-- 是BOSS时
				isBoss = false,
			},
			-- 狂暴
			berserk = {
				-- 有扫击时
				hasRake = true,
				-- 有撕扯时
				hasRip = true,
				-- 是斩杀时
				isKill = true,
				-- 是BOSS时
				isBoss = true,
			},
		}
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
		args = {
			-- 时机
			timing = {
				type = "group",
				name = "时机",
				desc = "设置法术等触发时机",
				order = 1,
				args = {
					killHealth = {
						type = "range",
						name = "斩杀生命",
						desc = "目标生命小于或等于该百分比时为斩杀",
						order = 6,
						min = 0,
						max = 100,
						step = 1,
						get = function()
							return self.db.profile.timing.killHealth
						end,
						set = function(value)
							self.db.profile.timing.killHealth = value
						end
					},
					energyDeficit = {
						type = "range",
						name = "能量匮乏",
						desc = "当能量小于或等于该值时为能量匮乏",
						order = 6,
						min = 0,
						max = 100,
						step = 1,
						get = function()
							return self.db.profile.timing.energyDeficit
						end,
						set = function(value)
							self.db.profile.timing.energyDeficit = value
						end
					},
					energySurplus = {
						type = "range",
						name = "能量富裕",
						desc = "当能量大于或等于该值时为富裕",
						order = 6,
						min = 0,
						max = 100,
						step = 1,
						get = function()
							return self.db.profile.timing.energySurplus
						end,
						set = function(value)
							self.db.profile.timing.energySurplus = value
						end
					},
					jewelry1 = {
						type = "group",
						name = "饰品1",
						desc = "设置饰品1施放时机，注意是并且条件",
						order = 4,
						args = {
							hasRake = {
								type = "toggle",
								name = "有扫击时",
								desc = "目标有扫击减益时",
								order = 1,
								get = function()
									return self.db.profile.timing.jewelry1.hasRake
								end,
								set = function(value)
									self.db.profile.timing.jewelry1.hasRake = value
								end
							},
							hasRip = {
								type = "toggle",
								name = "有撕扯时",
								desc = "目标有撕扯减益时",
								order = 1,
								get = function()
									return self.db.profile.timing.jewelry1.hasRip
								end,
								set = function(value)
									self.db.profile.timing.jewelry1.hasRip = value
								end
							},
							isKill = {
								type = "toggle",
								name = "已斩杀时",
								desc = "目标进入斩杀时",
								order = 1,
								get = function()
									return self.db.profile.timing.jewelry1.isKill
								end,
								set = function(value)
									self.db.profile.timing.jewelry1.isKill = value
								end
							},
							isBoss = {
								type = "toggle",
								name = "是BOSS时",
								desc = "目标是BOSS时",
								order = 1,
								get = function()
									return self.db.profile.timing.jewelry1.isBoss
								end,
								set = function(value)
									self.db.profile.timing.jewelry1.isBoss = value
								end
							},
						}
					},
					jewelry2 = {
						type = "group",
						name = "饰品2",
						desc = "设置饰品2使用时机，注意是并且条件",
						order = 5,
						args = {
							hasRake = {
								type = "toggle",
								name = "有扫击时",
								desc = "目标有扫击减益时",
								order = 1,
								get = function()
									return self.db.profile.timing.jewelry2.hasRake
								end,
								set = function(value)
									self.db.profile.timing.jewelry2.hasRake = value
								end
							},
							hasRip = {
								type = "toggle",
								name = "有撕扯时",
								desc = "目标有撕扯减益时",
								order = 1,
								get = function()
									return self.db.profile.timing.jewelry2.hasRip
								end,
								set = function(value)
									self.db.profile.timing.jewelry2.hasRip = value
								end
							},
								isKill = {
								type = "toggle",
								name = "已斩杀时",
								desc = "目标进入斩杀时",
								order = 1,
								get = function()
									return self.db.profile.timing.jewelry2.isKill
								end,
								set = function(value)
									self.db.profile.timing.jewelry2.isKill = value
								end
							},
							isBoss = {
								type = "toggle",
								name = "是BOSS时",
								desc = "目标是BOSS时",
								order = 1,
								get = function()
									return self.db.profile.timing.jewelry2.isBoss
								end,
								set = function(value)
									self.db.profile.timing.jewelry2.isBoss = value
								end
							},
						}
					},
					berserk = {
						type = "group",
						name = "狂暴",
						desc = "设置狂暴使用时机，注意是并且条件",
						order = 5,
						args = {
							hasRake = {
								type = "toggle",
								name = "有扫击时",
								desc = "目标有扫击减益时",
								order = 1,
								get = function()
									return self.db.profile.timing.berserk.hasRake
								end,
								set = function(value)
									self.db.profile.timing.berserk.hasRake = value
								end
							},
							hasRip = {
								type = "toggle",
								name = "有撕扯时",
								desc = "目标有撕扯减益时",
								order = 1,
								get = function()
									return self.db.profile.timing.berserk.hasRip
								end,
								set = function(value)
									self.db.profile.timing.berserk.hasRip = value
								end
							},
								isKill = {
								type = "toggle",
								name = "已斩杀时",
								desc = "目标进入斩杀时",
								order = 1,
								get = function()
									return self.db.profile.timing.berserk.isKill
								end,
								set = function(value)
									self.db.profile.timing.berserk.isKill = value
								end
							},
							isBoss = {
								type = "toggle",
								name = "是BOSS时",
								desc = "目标是BOSS时",
								order = 1,
								get = function()
									return self.db.profile.timing.berserk.isBoss
								end,
								set = function(value)
									self.db.profile.timing.berserk.isBoss = value
								end
							},
							energyDeficit = {
								type = "toggle",
								name = "能量匮乏",
								desc = "当自己能量匮乏时",
								order = 1,
								get = function()
									return self.db.profile.timing.berserk.energyDeficit
								end,
								set = function(value)
									self.db.profile.timing.berserk.energyDeficit = value
								end
							},
						}
					},
				}
			},
			-- 其它
			other = {
				type = "header",
				name = "其它",
				order = 3,
			},
			debug = {
				type = "toggle",
				name = "调试模式",
				desc = "开启或关闭调试模式",
				order = 4,
				get = "IsDebugging",
				set = "SetDebugging"
			},
			level = {
				type = "range",
				name = "调试等级",
				desc = "设置或获取调试等级",
				order = 5,
				min = 1,
				max = 3,
				step = 1,
				get = "GetDebugLevel",
				set = "SetDebugLevel"
			}
		}
	}
end

-- 插件打开
function DruidCat:OnEnable()
	self:LevelDebug(3, "插件打开")

	-- 猛虎之怒时间
	self.tigerFuryTimer = GetTime() - 18
	-- 撕扯时间
	self.ripTimer = GetTime() - 12

	-- 注册施法瞬间事件
	self:RegisterEvent("SpellStatus_SpellCastInstant")
	-- 注册施法失败事件
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

-- 施法瞬间
---@param id number 法术标识
---@param name string 法术名称
---@param rank number 法术等级
---@param fullName string 法术全名
function DruidCat:SpellStatus_SpellCastInstant(id, name, rank, fullName)
	self:LevelDebug(3, "施法瞬间；法术名称：%", name)

	-- 记录撕扯时间
	if name == "撕扯" then
		self.ripTimer = GetTime()
	end

	-- 记录猛虎之怒时间
	if name == "猛虎之怒" then
		self.tigerFuryTimer = GetTime()
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
function DruidCat:SpellStatus_SpellCastFailure(sId, sName, sRank, sFullName, isActiveSpell, UIEM_Message, CMSFLP_SpellName, CMSFLP_Message)
	self:LevelDebug(3, "施法失败；法术名称：%s；错误提示：%s", sName, UIEM_Message)
end

-- ​​撕裂：自适应一键输出
function DruidCat:Tear()
	-- 可流血
	local canBleed = Bleed:CanBleed()
	-- 战斗中
	local combat = UnitAffectingCombat("player")
    -- 战斗中目标选择为近战，脱战为最远距离
    if combat then
	    SetCVar("targetNearestDistance", 5)
    else
	    SetCVar("targetNearestDistance", 41)
    end

	if Buff:FindUnit("潜行") then
		-- 潜行中
		if canBleed then
			if
				-- 无猛虎之怒
				not Buff:FindUnit("猛虎之怒") 
			then
				-- 补猛虎
				CastSpellByName("猛虎之怒")
			else
				-- 流血
				CastSpellByName("突袭")
			end
		else
			-- 伤害
			CastSpellByName("毁灭")
		end
	else
		-- 非潜行中
		if self.helper:IsCat() then
			-- 猫形态
            --无目标切换目标
            if not UnitExists("target") then
                TargetLastEnemy()
            end
            --无目标或者目标死亡切换目标
            if not UnitExists("target") or UnitIsDeadOrGhost("target") then
                TargetNearestEnemy()
            end
			-- 自动攻击
			self.helper:AutoAttack()

			-- 爪击能耗
			local clawEnergy = self.helper:GetSpellConsume("爪击")
			-- 扫击能耗
			local rakeEnergy = self.helper:GetSpellConsume("扫击")
			-- 撕碎能耗
			local shredEnergy = self.helper:GetSpellConsume("撕碎")

			-- 变形回能
			local metamorphicRecovery = self.helper:GetMetamorphicRecovery()

			if
				-- 无冷却时间（公共冷却）
				Spell:IsReady("猎豹形态")
				and (
					-- 能量不够爪击(减2秒呼吸回能20)
					UnitMana("player") < clawEnergy - 20
					or (
						-- 能量不够扫击（变身10s以后，能量足够不考虑回能）
						UnitMana("player") < rakeEnergy
						-- 与上个猛虎已过去10秒以上
						and GetTime() - self.tigerFuryTimer > 10
					)
					or (
						-- 能量不够撕碎(减2秒呼吸回能20)
						UnitMana("player") < shredEnergy - 20
						-- 不可流血
						and not canBleed
						-- 在背后
						and Behind:IsBehind()
						-- 低于4连击点
						and GetComboPoints("target") < 4
					)
				)
				-- 变形回能60及以上
				and metamorphicRecovery >= 60
				-- 法力足够变形（猎豹形态需要348法力）
				and self.helper:GetMana() >= 400
				-- 无节能施法
				and not Buff:FindUnit("节能施法")
			then
				-- 取消猫形态
				CastSpellByName("猎豹形态")
                -- 取消当前目标，避免人形普攻
                ClearTarget()
			else
				-- 有扫击
				local hasRake = self.helper:HasDebuff('扫击')
				-- 有撕扯
				local hasRip = self.helper:HasDebuff('撕扯')
				-- 是斩杀
				local isKill = Health:GetRemaining("target") <= self.db.profile.timing.killHealth
				-- 能量匮乏
				local energyDeficit = UnitMana("player") <= self.db.profile.timing.energyDeficit
				-- 是BOSS
				local isBoss = Behind:IsBoss()

				if
					-- 饰品1可用
					self.helper:CanJewelry(13)
					-- 有扫击
					and (not self.db.profile.timing.jewelry1.hasRake or hasRake)
					-- 有撕扯
					and (not self.db.profile.timing.jewelry1.hasRip or hasRip)
					-- 是斩杀
					and (not self.db.profile.timing.jewelry1.isKill or isKill)
					-- 是BOOS
					and (not self.db.profile.timing.jewelry1.isBoss or isBoss)
				then
					-- 爆发
					UseInventoryItem(13)
				end

				if
					-- 饰品2可用
					self.helper:CanJewelry(14)
					-- 有扫击
					and (not self.db.profile.timing.jewelry2.hasRake or hasRake)
					-- 有撕扯
					and (not self.db.profile.timing.jewelry2.hasRip or hasRip)
					-- 是斩杀
					and (not self.db.profile.timing.jewelry2.isKill or isKill)
					-- 是BOOS
					and (not self.db.profile.timing.jewelry2.isBoss or isBoss)
				then
					-- 爆发
					UseInventoryItem(14)
				end

				if
					-- 狂暴就绪
					Spell:IsReady("狂暴")
					-- 有扫击
					-- and (not self.db.profile.timing.berserk.hasRake or hasRake)
					-- 有撕扯
					-- and (not self.db.profile.timing.berserk.hasRip or hasRip)
					-- 是斩杀
					and (not self.db.profile.timing.berserk.isKill or isKill)
					-- 是BOOS
					and (not self.db.profile.timing.berserk.isBoss or isBoss)
					-- 能量匮乏
					and (not self.db.profile.timing.berserk.energyDeficit or energyDeficit)
				then
					-- 回能
					CastSpellByName("狂暴")
				end

				if
					-- 无猛虎之怒
					not Buff:FindUnit("猛虎之怒") 
					-- 能量有变形回能及以上数
					and UnitMana("player") >= metamorphicRecovery
					-- 可流血
					and canBleed
					-- 无血之狂暴
					or not Buff:FindUnit("血之狂暴")
				then
					-- 补猛虎
					CastSpellByName("猛虎之怒")
				end

				if
					-- 有节能施法
					Buff:FindUnit("节能施法")
					-- 在背后
					and Behind:IsBehind()
				then
					-- 消节能
					CastSpellByName("撕碎")
				elseif
					-- 是BOSS
					isBoss
					-- 无精灵之火
					and not Buff:FindUnit("精灵之火", "target")
				then
					-- 补精灵之火
					CastSpellByName("精灵之火（野性）")
				end
	
				if
					-- 可流血
					canBleed
					-- 可撕扯
					and self.helper:CanDebuff("撕扯")
					-- 有星
					and GetComboPoints("target") > 0
				then
					-- 补撕扯
					CastSpellByName("撕扯")
				elseif
					-- 有3星以上
					GetComboPoints("target") > 3
					-- 能量低于70
					and UnitMana("player") < 70
					and (
						-- 与撕扯已过去9秒以内，撕扯剩余3s内就不放凶猛，留星等补撕扯
						GetTime() - self.ripTimer < 9
						-- 不可流血
						or not canBleed
					)
				then
					-- 消星
					CastSpellByName("凶猛撕咬")
				end

				if
					-- 可流血
					canBleed
					-- 可扫击
					and self.helper:CanDebuff("扫击")
					-- 无强化攻击
					and not Buff:FindUnit("强化攻击")
				then
					-- 补扫击
					CastSpellByName("扫击")
				end

				if
					(
						-- 有强化攻击
						Buff:FindUnit("强化攻击")
						-- 能量有60及以上
						or UnitMana("player") >= 60
                        -- 有撕裂神像
						or Buff:FindUnit("撕裂神像")
						-- 不可流血（爪击不享受迸裂创伤）
						or not canBleed
					)
                    -- 撕碎能量消耗低于49
					and shredEnergy < 49
					-- 在背后
					and Behind:IsBehind()
				then
					-- 背刺
					CastSpellByName("撕碎")
				else
					-- 消能量
					CastSpellByName("爪击")
				end

				-- 骗节能
				if Spell:IsReady("精灵之火（野性）") then
					CastSpellByName("精灵之火（野性）")
				end
			end
		else
			-- 变猫形态（变形回能量）
			self.helper:SwitchForm(3)
		end
	end
	
	-- /console Sound_EnableErrorSpeech 1
	-- 清除提示（能量不足、法术未就绪等）
	UIErrorsFrame:Clear()
end

-- 冲锋：切换到熊形态，冲锋目标
function DruidCat:Charge()
	-- 技能就绪
	if Spell:IsReady("野性冲锋") then
		local rorm = self.helper:GetForm()
		if rorm == 1 then
			-- 熊形态
			if UnitMana("player") < 5 and Spell:IsReady("狂怒") then
				CastSpellByName("狂怒")
			end

			if UnitMana("player") >= 5 then
				CastSpellByName("野性冲锋")
			else
				Prompt:Warning("冲锋：怒气不足")
			end
		else
			-- 非熊形态
			if self.helper:GetMana() >= 400 then
				self.helper:SwitchForm(1)
			else
				Prompt:Warning("冲锋：变形法力不足")
			end
		end
	else
		Prompt:Warning("冲锋：技能冷却中")
	end
end

-- 重击：换到熊形态，昏迷目标
function DruidCat:Bash()
	if Spell:IsReady("重击") then
		local rorm = self.helper:GetForm()
		if rorm == 1 then
			-- 熊形态
			if UnitMana("player") < 10 and Spell:IsReady("狂怒") then
				CastSpellByName("狂怒")
			end

			if UnitMana("player") >= 10 then
				CastSpellByName("重击")
			else
				Prompt:Warning("重击：怒气不足")
			end
		else
			-- 非熊形态
			if self.helper:GetMana() >= 400 then
				self.helper:SwitchForm(1)
			else
				Prompt:Warning("重击：变形法力不足")
			end
		end
	else
		Prompt:Warning("重击：技能冷却中")
	end
end

-- 潜行：换到猫形态，潜行
function DruidCat:Stealth()
	-- 战斗中
	local combat = UnitAffectingCombat("player")
	-- 正潜行中时，法术将处于冷却状态
	if Buff:FindUnit("潜行") then
		Prompt:Warning("潜行：已在潜行状态")
	elseif Spell:IsReady("潜行") then
		local rorm = self.helper:GetForm()
		if rorm == 3 then
			-- 猫形态
			if Buff:FindUnit("潜行") then
				Prompt:Warning("潜行：已在潜行状态")
			elseif combat then
				Prompt:Warning("潜行：在战斗中")
            else
				CastSpellByName("潜行")
			end
		else
			-- 非猫形态
			if self.helper:GetMana() >= 400 then
				self.helper:SwitchForm(3)
			else
				Prompt:Warning("潜行：变形法力不足")
			end
		end
	else
		Prompt:Warning("潜行：技能冷却中")
	end
end

--[[

天赋:
迸裂创伤（3/3）：每个流血效果使爪击伤害提高[10/20/30]%，凶猛撕咬伤害提高[3/4/5]%。（解决爪击伤害的问题）
血性狂乱（2/2）：猛虎之怒持续时间延长[6/12]秒。使用猛虎之怒还获得血之狂暴增益（攻击速度提高[10/20]%，持续12秒）
原始狂怒（2/2）：造成暴击后额外增加一星。
远古蛮力（2/2）：流血周期性伤害将恢复[5/10]能量。（解决输出能量问题）

套装:
起源套甲（5/5）- 强化攻击：下一个XXX、XXX暴击几率提高N%（T2.5套装效果）

技能：
猎豹形态：消耗348法力
精灵之火（野性）（Faerie Fire (Feral)）：冷却6秒，持续40秒降低175护甲
猛虎之怒（Tiger's Fury）：消耗30能量，持续6秒伤害提高50点，变形效果消失
狂暴（Berserk）：冷却6分，持续20秒100%回能速度，移除恐惧
爪击（Claw）：消耗45能量，获得连击点，产生伤害
扫击（Rake）：消耗40能量，获得连击点，持续9秒伤害（3秒一跳）
撕碎（Shred）：消耗60能量，获得连击点，需要背后，产生伤害
毁灭（Ravage）：消耗60能量，获得连击点，需要潜行、背后，产生伤害
突袭（Pounce）：消耗50能量，获得连击点，需要潜行、背后，眩晕2秒，施加血袭减益（持续18秒伤害，3秒一跳）
撕扯（Rip）：消耗30能量、连击点，持续12秒伤害（2秒一跳）
凶猛撕咬（Ferocious Bite）：消耗35能量、连击点，产生伤害

]]
