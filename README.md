> 已不再维护，请使用可视化通用[一键宏](https://gitee.com/ku-ba/OneClickMacro)插件 2025-9-2 xhwsd@qq.com

# 猫德辅助插件
> 如有建议或BUG请至[ku-ba/DruidCat](https://gitee.com/ku-ba/DruidCat)代码库[提交问题](https://gitee.com/ku-ba/DruidCat/issues)！


## 使用
- 安装`!Libs`插件
- [可选][[文档](https://github.com/xhwsd/SuperMacro/)][[下载](https://github.com/xhwsd/SuperMacro/archive/master.zip)]安装`SuperMacro`插件，安装后将获得更多宏位
- [[文档](https://github.com/xhwsd/DruidCat/)][[下载](https://github.com/xhwsd/DruidCat/archive/main.zip)]安装`DruidCat`插件
- 基于插件提供的函数，创建普通或超级宏
- 将宏图标拖至动作条，然后使用宏

> 确保插件最新版本、已适配乌龟服、目录名正确（如删除末尾`-main`、`-master`等）


## 可用宏

###  ​撕裂

> 自适应一键输出

```lua
/script -- CastSpellByName("爪击")
/script DruidCat:Tear()
```

### 冲锋

> 切换到熊形态，冲锋目标

```lua
/script -- CastSpellByName("野性冲锋")
/script DruidCat:Charge()
```

### 重击

>  切换到熊形态，昏迷目标

```lua
/script -- CastSpellByName("重击")
/script DruidCat:Bash()
```

### 潜行

> 切换到猫形态，潜行

```lua
/script -- CastSpellByName("潜行")
/script DruidCat:Stealth()
```


## 参考

### 天赋
[![跳转至天赋模拟器](Talent.png)](https://talents.turtle-wow.org/druid?points=BSAaAIAAAAAAAAFYADBYTSAKFQBAAoAAAAAAAAAAAAA=)


### 文档
- [乌龟服1.17.2野德输出不完全指北](https://www.bilibili.com/opus/1058900087781982213)
- [乌龟服猫德的持续探索](https://luntan.turtle-wow.org/viewtopic.php?t=222) 


