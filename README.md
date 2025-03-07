# 猫德辅助插件

> __自娱自乐，不做任何保证！__  
> 如遇到BUG可反馈至 xhwsd@qq.com 邮箱


## 使用
- 安装`!Libs`插件
- [可选][[文档](https://github.com/xhwsd/SuperMacro/)][[下载](https://github.com/xhwsd/SuperMacro/archive/master.zip)]安装`SuperMacro`插件，安装后将获得更多宏位
- [[文档](https://github.com/xhwsd/DruidCat/)][[下载](https://github.com/xhwsd/DruidBird/DruidCat/master.zip)]安装`DruidBird`插件
- 基于插件提供的函数，创建普通或超级宏
- 将宏图标拖至动作条，然后使用宏

> 确保插件最新版本、已适配乌龟服、目录名正确（如删除末尾`-main`、`-master`等）


## 可用宏


### 背刺

> 在背后攻击敌人

```
/script -- CastSpellByName("撕碎")
/script DruidCat:BackStab()
```

逻辑描述：
- 潜行时使用毁灭
- 非潜行时撕碎
- 会对目标使用精灵之火
- 5连击时会执行终结


### 攒点

> 攒连击点

```
/script -- CastSpellByName("爪击")
/script DruidCat:AccumulatePoint()
```

逻辑描述：
- 会对目标使用精灵之火
- 5连击时会执行终结


### 终结

> 消耗连击点

```
/script -- CastSpellByName("凶猛撕咬")
/script DruidCat:Termination()
```

逻辑描述：
- 会根据目标类型抉择使用撕扯还是凶猛撕咬


## 指令
- `/mdfz tsms` - 调试模式：开启或关闭调试模式
- `/mdfz tsdj [等级]` - 调试等级：设置或获取调试等级，等级取值范围`1~3`

## 参考天赋
![参考天赋](/参考天赋/2025-1-13.png)
