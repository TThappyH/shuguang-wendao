# V10 Core Gameplay Framework

## 目标

把 Godot 版本从“模型与地图可显示”推进到可持续扩张的 3D 动作肉鸽骨架，同时保留核心支柱：

> 人走位，剑作战。

本阶段不靠代码量填充质量，而是建立能反复调试、替换美术和验证玩法的运行闭环。

## 运行架构

```text
Main
├─ GameEvents (autoload)
├─ PlayerController
├─ SwordManager
│  └─ FlyingSword x3 / existing FSM
├─ EncounterDirector
│  └─ EnemyController / explicit FSM
├─ RunProgression
├─ CombatFeedback / fixed pool
├─ LevelBuilder
│  └─ RodinAssetRegistry(qingyun_island)
└─ GameHUD
```

### 数据层

- `EnemyArchetypeData`：敌人生命、速度、行为、伤害、奖励和 Rodin 模型槽位。
- `UpgradeDefinition`：升级目标、属性、增量、权重和最大叠层。
- `.tres` 作为正式调参入口，逻辑脚本不再硬编码每一档数值。

### 战斗闭环

1. 遭遇导演按 `WARMUP → BUILD → PRESSURE → SURGE → RECOVER` 调整压力。
2. 三类数据模型组成不同敌群形状：逐影直追、游煞侧压、镇岳锚定。
3. 三柄剑保留独立 FSM，并使用线段扫掠检测，避免高速穿模。
4. 飞剑第一、第二目标都真实结算伤害；不会命中 A 后自动转向 B。
5. 击破敌人获得道行，升级时暂停并给出三选一。
6. 固定对象池负责短促命中脉冲，镜头 trauma 负责有限震动，不制造持续节点增长。

### 可观测性

F3 面板显示阶段、目标敌数、峰值敌数、累计生成、击杀、命中效率、连穿率、移动距离、承伤和反馈池容量。

## 借鉴边界

- [Maaack/Godot-Game-Template](https://github.com/Maaack/Godot-Game-Template)：场景边界、暂停和可扩展项目骨架。
- [DarkRewar/SurvivorsStarterKit](https://github.com/DarkRewar/SurvivorsStarterKit)：数据驱动的敌群、成长和 Survivors-like 循环。
- [Godot 官方 Demo](https://github.com/godotengine/godot-demo-projects)：Godot 4 3D 节点与运行约定。
- [LimboAI](https://github.com/limbonaut/limboai) 与 [Beehave](https://github.com/bitbrain/beehave)：只借鉴显式状态/行为拆分；当前小规模原型不引入大型 AI 插件。

第三方仓库没有直接拷入生产树，避免许可证、维护面和插件耦合提前膨胀。

## 当前人工验收重点

1. 走位是否能把敌人排成穿透线。
2. 升级三选一是否能形成可感知差异。
3. `WARMUP/BUILD/PRESSURE` 的节奏是否太慢或太急。
4. 命中震动是否清楚但不晕。
5. 1 / 3 / 8 调试敌群是否稳定。

10 分钟主观可玩性仍由用户亲自测试；自动门禁只覆盖短生命周期和结构正确性。
