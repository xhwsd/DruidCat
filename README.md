# 猫德辅助插件

> __自娱自乐，不做任何保证！__  
> 如遇到BUG可反馈至 xhwsd@qq.com 邮箱


## 使用
- 安装`!Libs`插件
- 可选的，安装[SuperMacro](https://ghgo.xyz/https://github.com/xhwsd/SuperMacro/archive/master.zip)插件
- 安装[DaruidCat](https://ghgo.xyz/https://github.com/xhwsd/DaruidCat/archive/master.zip)插件
- 基于插件提供的函数，创建普通或超级宏
- 将宏图标拖至动作条，然后使用宏

> 请确保依赖插件最新版和已适配乌龟，插件目录名正确（如删除末尾`-main`等）


## 可用宏


### 背刺

> 在背后攻击敌人

```
/script -- CastSpellByName("撕碎")
/script DaruidCat:BackStab()
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
/script DaruidCat:AccumulatePoint()
```

逻辑描述：
- 会对目标使用精灵之火
- 5连击时会执行终结


### 终结

> 消耗连击点

```
/script -- CastSpellByName("凶猛撕咬")
/script DaruidCat:Termination()
```

逻辑描述：
- 会根据目标类型抉择使用撕扯还是凶猛撕咬


## 简单宏
- `/md debug` - 开启或关闭调试模式，调试模式下会输出详细信息
- `/md level [level]` 设置调试等级，`level`取值`1~3`；设置调试模式下输出等级
