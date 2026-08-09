# V8.2 GitHub 实现调研

本轮调研目标不是复制模板，而是确认成熟的波次导演、敌人战术与程序化场景拆分方式，再按《曙光问道》的单文件运行架构重新实现。

## 参考仓库

| 仓库 | 重点文件 / 概念 | 本项目采用方式 |
| --- | --- | --- |
| [pariharshyamu/gama](https://github.com/pariharshyamu/gama) | `WaveDirector.ts`、`Objectives.ts`、utility AI、横向骚扰和空间网格 | 将遭遇导演从敌人实体更新中拆出；区域、遭遇模板和战术状态数据驱动；只参考架构概念 |
| [DarkRewar/SurvivorsStarterKit](https://github.com/DarkRewar/SurvivorsStarterKit) | Survivors-like 波次、成长和敌群节奏 | 保留持续敌群压力，同时插入具有开场、分批入场和清场的正式遭遇 |
| [ptidejteam/ecs-survivors](https://github.com/ptidejteam/ecs-survivors) | ECS Survivors 压力管理 | 仅比较系统边界；仓库为 GPL，不复制代码 |
| [dimartarmizi/threejs-procedural-terrain](https://github.com/dimartarmizi/threejs-procedural-terrain) | terrain presets、颜色分区、tile streaming | 用低 draw-call 实例化地标与地表色块建立区域辨识；仓库未显示许可证，不复制代码 |

## 落地结论

1. **导演独立**：区域遭遇使用 `REST → TELEGRAPH → ACTIVE → REST`，不把波次条件塞进单个敌人。
2. **队列入场**：敌人通过 stagger queue 分批生成，避免同一帧创建整群对象。
3. **柔性压力**：压力值限制在 `0.18～0.92`，仅根据血量与清场速度小幅变化。
4. **战术可读**：远程使用 `APPROACH / RETREAT / HARASS`，重甲使用 `GUARD`，蛮兽使用 `WINDUP / CHARGE`。
5. **区域先读色块，再读地标**：竹、莲、残剑、丹岩全部使用共享几何或 `InstancedMesh`，不靠堆独立高面数对象。
6. **记录闭环**：区域发现、遭遇开始/清场、刷怪数、击败数和导演压力进入运行记录与复盘工具。

## 许可证边界

- MIT 仓库只借鉴通用架构思路，本项目实现代码为重新编写。
- GPL 或未明确许可证仓库只做概念对照，不复制源码、资产或文本。
