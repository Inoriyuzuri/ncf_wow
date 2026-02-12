# NCF 使用指南

## 简介

NCF 是一个魔兽世界技能循环辅助插件，支持多职业多专精，帮助玩家优化输出/治疗/坦克循环。

---

## 安装

### 文件结构

```
nn/
└── scripts/
    ├── _ncf.nn           # 核心文件
    ├── ncf_ui.nn         # UI 界面
    ├── ncf_helper.nn     # 辅助函数
    └── rotations/        # 循环文件夹
        ├── mage_arcane.lua
        ├── warrior_fury.lua
        ├── deathknight_frost.lua
        └── ...
```

### 安装步骤

1. 将核心文件 (`_ncf.nn`, `ncf_ui.nn`, `ncf_helper.nn`) 放入 `nn/scripts/` 目录
2. 将职业循环文件 (`.lua`) 放入 `nn/scripts/rotations/` 目录
3. 重载界面 `/reload`

---

## 悬浮面板

悬浮面板是 NCF 的主要显示界面，显示在屏幕上方，可拖动调整位置。

### 面板组件

从左到右依次为:

| 组件 | 功能 |
|------|------|
| **推荐技能图标** | 显示当前建议释放的技能图标，暂停时显示红色 X |
| **TTD 面板** | 显示目标预估存活时间 (Time To Die) |
| **禁用技能面板** | 显示当前被禁用的技能图标列表 |
| **状态栏** | 显示: 开启/暂停状态、爆发/划水模式、敌人数量 |

### 面板状态说明

**状态栏显示格式:** `已开启-爆发 敌人:5`

| 状态 | 颜色 | 说明 |
|------|------|------|
| 已开启 | 绿色 | 循环正在运行 |
| 已暂停 | 红色 | 循环已停止 |
| 爆发 | 金色 | 爆发模式，使用大技能 |
| 划水 | 绿色 | 划水模式，不使用爆发技能 |

### 未进战提示

当推荐技能图标上方显示「未进战」时，表示当前未进入战斗状态，循环等待中。

### 显示选项

在设置面板中可以单独开关各组件:
- 推荐技能图标
- TTD 面板
- 禁用技能显示
- 状态栏

---

## 设置面板

点击「设置」宏或使用 `/run NCFsettings()` 打开设置面板。

### 基础设置

| 设置项 | 说明 |
|--------|------|
| 开启快捷键 | 绑定循环开关的按键 |
| 爆发/划水切换 | 绑定爆发模式切换的按键 |

### 打断设置

| 设置项 | 说明 |
|--------|------|
| 读条剩余 X 秒内打断 | 当敌人读条剩余时间小于此值时打断 |
| 0 = 立即打断 | 设为 0 则立即打断 |

### 自动索敌设置

| 设置项 | 说明 |
|--------|------|
| 启用自动索敌 | 自动切换到最优目标 |
| 检查距离 | 目标超出范围时自动切换 |
| 检查身前 | 目标在身后时自动切换 |
| 自定义范围 | 设置索敌范围 (留空 = 自动判断) |

### 自动喝药设置

| 设置项 | 说明 |
|--------|------|
| 自动喝药阈值 | 血量低于此百分比时自动喝药 |
| 0 = 关闭 | 设为 0 则不自动喝药 |
| 默认值: 35% | 血量 ≤ 35% 时自动使用治疗药水/治疗石 |

### 悬浮面板显示选项

| 选项 | 说明 |
|------|------|
| 状态栏 | 显示/隐藏状态栏 |
| 推荐技能 | 显示/隐藏推荐技能图标 |
| TTD | 显示/隐藏 TTD 面板 |
| 禁用显示 | 显示/隐藏禁用技能列表 |

### 开发者选项

| 选项 | 说明 |
|------|------|
| [dev]聊天框输出释放 | 在聊天框显示每次释放的技能 (调试用) |

---

## 技能模式设置

点击悬浮面板或使用宏打开技能模式设置面板。

### 技能模式

每个技能有三种模式:

| 模式 | 显示 | 说明 |
|------|------|------|
| 正常 (normal) | 绿色边框 | 正常使用 |
| 爆发 (burst) | 橙色边框 | 仅在爆发模式下使用 |
| 禁用 (skip) | 红色边框 | 不使用此技能 |

### 爆发保护 (TTD)

部分爆发技能可以设置 TTD 保护，当目标预估存活时间小于设定值时，不会使用该技能，避免浪费大招。

### 快捷键绑定

每个技能可以单独绑定快捷键:
- **左键点击**: 设置快捷键
- **右键点击**: 清除快捷键
- **按下快捷键**: 切换技能禁用/启用状态

---

## 宏命令

NCF 会自动创建以下宏:

| 宏名称 | 功能 | 命令 |
|--------|------|------|
| NCF | 开关循环 | `/run NCFswitch()` |
| NCF爆发 | 切换爆发/划水模式 | `/run NCFburst()` |
| NCF智能 | 切换智能目标 | `/run NCFsmart()` |
| 设置 | 打开设置面板 | `/run NCFsettings()` |
| 显示Buff | 显示玩家当前 Buff | `/run NCFbuffs()` |
| 显示Debuff | 显示目标当前 Debuff | `/run NCFdebuffs()` |
| NCF插入 | 插入技能到队列 | `/run NCFInsert(技能ID)` |
| NCF队列 | 显示当前插入队列 | `/run NCFQueue()` |
| LR前跳 | 猎人前跳宏 | `/run NCFDisengage()` |

---

## 插入宏 (NCFInsert)

插入宏用于在循环中插入自定义技能，优先级高于循环建议的技能。

### 使用方法

```
/run NCFInsert(技能ID)
```

或使用技能名称:

```
/run NCFInsert("技能名称")
```

### 示例

**插入嗜血:**
```
/run NCFInsert(2825)
```

**插入英勇:**
```
/run NCFInsert("英勇气概")
```

### 查看队列

```
/run NCFQueue()
```

显示当前插入队列中的技能。

### 使用场景

- 需要临时使用某个技能时
- 循环没有自动建议但你想手动触发的技能
- 配合 WeakAura 或其他插件触发

### 注意事项

- 技能必须已就绪 (不在 CD 中)
- 脱战后队列自动清空
- 技能成功施放后自动从队列移除

---

## 猎人前跳宏 (NCFDisengage)

猎人专用宏，实现「前跳」效果。

### 原理

1. 记录当前朝向
2. 瞬间转身 180 度
3. 施放脱离 (Disengage)
4. 瞬间转回原朝向

### 使用方法

创建宏:

```
#showtooltip 脱离
/run NCFDisengage()
```

或英文客户端:

```
#showtooltip Disengage
/run NCFDisengage()
```

### 效果

按下宏后，角色会向前方跳跃，而不是向后跳。

---

## 快捷键设置

### 支持的快捷键格式

| 类型 | 示例 |
|------|------|
| 单个按键 | `F1`, `1`, `X`, `G` |
| 组合键 | `CTRL-1`, `SHIFT-F`, `ALT-X` |
| 多修饰键 | `CTRL-SHIFT-1`, `CTRL-ALT-F` |
| 鼠标按键 | `BUTTON3` (中键), `BUTTON4`, `BUTTON5` |
| 鼠标滚轮 | `MOUSEWHEELUP`, `MOUSEWHEELDOWN` |
| 鼠标组合键 | `CTRL-BUTTON4`, `SHIFT-BUTTON5` |

### 设置方法

1. 点击快捷键按钮
2. 按下想要绑定的按键/组合键
3. 按 ESC 取消
4. 右键点击清除绑定

---

## 职业专精支持

### 当前支持的专精

| 职业 | 专精 |
|------|------|
| 死亡骑士 | 冰霜、邪恶、鲜血 |
| 恶魔猎手 | 浩劫（虚空）|
| 德鲁伊 | 恢复 |
| 猎人 | 野兽控制、生存 |
| 法师 | 奥术 |
| 武僧 | 酒仙 |
| 牧师 | 暗影 |
| 萨满 | 恢复 |
| 术士 | 恶魔 |
| 战士 | 狂怒、防护 |

---

## 常见问题

### Q: 插件没有显示技能提示？

**A:** 检查以下几点:
1. 确保循环已开启（状态栏显示「已开启」）
2. 确保有目标且目标可攻击
3. 确保 `rotations` 文件夹中有对应专精的循环文件
4. 文件命名格式: `职业_专精.lua` (如 `mage_arcane.lua`)

### Q: 某个技能不想自动使用？

**A:** 在技能模式设置中点击该技能图标，切换到红色（禁用）模式

### Q: 爆发技能没有自动使用？

**A:** 检查以下几点:
1. 确保爆发模式已开启（状态栏显示「爆发」）
2. 确保该技能不是红色禁用状态
3. 检查 TTD 保护设置，Boss 血量太低可能触发保护

### Q: 打断时机不对？

**A:** 调整打断设置:
- 数值越大，打断越早
- 数值越小，打断越晚
- 设为 0 表示立即打断

### Q: 如何强制使用某个技能？

**A:** 使用插入宏:
```
/run NCFInsert(技能ID)
```
技能ID可以在 Wowhead 等网站查询

### Q: 悬浮面板位置怎么保存？

**A:** 拖动面板到想要的位置后，位置会自动保存。

### Q: 猎人前跳宏不生效？

**A:** 确保:
1. 使用 `/run NCFDisengage()` 而不是 `/cast 脱离`
2. 脱离技能不在 CD 中
3. 角色没有被控制

---

## 循环文件结构 (开发者参考)

```lua
-- 1. 注册技能
NCF.RegisterSpells("CLASS", specIndex, {
    { id = 12345, name = "技能名", default = "normal" },
    { id = 67890, name = "爆发技能", default = "burst" },
})

-- 2. 定义 ID
local SPELL = { SpellName = 12345 }
local BUFF = { BuffName = 12345 }
local DEBUFF = { DebuffName = 12345 }
local TALENT = { TalentName = 12345 }

-- 3. 获取 Helper 函数
local HasBuff = NCF.HasBuff
local HasDebuff = NCF.HasDebuff
local HasTalent = NCF.HasTalent
-- ... 更多函数见 ncf_helper.nn

-- 4. 主循环
local function CreateRotation()
    local function Rotation()
        -- 获取状态
        local enemyCount = NCF.GetActiveEnemyAmount(10, false)
        
        -- 判断条件并返回技能
        if IsReady(SPELL.SomeSpell) then
            return "spell", SPELL.SomeSpell
        end
        
        return nil
    end
    return Rotation
end

return CreateRotation()
```

### 常用 Helper 函数

| 函数 | 说明 |
|------|------|
| `NCF.HasBuff(spellId, unit)` | 检查是否有 Buff |
| `NCF.HasDebuff(spellId, unit)` | 检查是否有 Debuff |
| `NCF.GetBuffRemain(spellId, unit)` | 获取 Buff 剩余时间 |
| `NCF.GetBuffStacks(spellId, unit)` | 获取 Buff 层数 |
| `NCF.HasTalent(talentId)` | 检查是否有天赋 |
| `NCF.GetSpellCooldownRemain(spellId)` | 获取技能 CD 剩余 |
| `NCF.GetSpellCharges(spellId)` | 获取技能充能数 (带小数) |
| `NCF.IsSpellReady(spellId)` | 技能是否就绪 |
| `NCF.GetActiveEnemyAmount(range, combat)` | 获取范围内敌人数量 |
| `NCF.GetInterruptTarget(range, facing)` | 获取可打断目标 |
| `NCF.GetUnitPower(unit, powerType)` | 获取资源值 |
| `NCF.GetUnitHealthPct(unit)` | 获取血量百分比 |
| `NCF.GetCombatTime()` | 获取战斗时间 |
| `NCF.ShouldSkipSpell(spellId)` | 技能是否被禁用 |
| `NCF.ShouldSkipBurstSpell(spellId)` | 爆发技能是否应跳过 |
| `NCF.MeetsSpellTTD(spellId)` | 检查是否满足 TTD 条件 |

---

## 更新日志

### v12.0
- 支持组合快捷键 (CTRL/SHIFT/ALT + 按键)
- 支持鼠标按键绑定 (BUTTON3/4/5)
- 支持鼠标滚轮绑定
- 优化打断系统
- 新增悬浮面板组件开关
- 新增 TTD 保护功能
- 新增自动喝药功能
- 新增多个职业循环
- 修复配置保存问题
- 优化 UI 界面

---

**祝游戏愉快！**