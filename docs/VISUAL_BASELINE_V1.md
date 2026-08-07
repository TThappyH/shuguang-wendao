# 《曙光问道》Visual Baseline V1

- 记录时间：2026-08-07 22:00 Asia/Hong_Kong
- 运行时：本地 V6.7.2 启动修复候选
- 基线状态：`BLOCKED`
- 本记录用途：为 Visual Quality Gate V1 提供第一份可复核的截图、Golden Scene 定义和实测指标；不是 PR #14 的合并批准。

## 1. 被测对象与提交边界

| 项目 | 值 |
|---|---|
| 被测文件 | `D:\1\曙光猎人_V6.7.2_启动修复版.html` |
| 被测文件 SHA-256 | `FBC38A5EEBB8024471C1F4AE6D9BC86500279814E495E47EA23ECDD980637364` |
| 测试副本 | `E:\shuguang_visual_gate_v1\曙光问道_V6.7.2_gate_instrumented.html` |
| 测试副本 SHA-256 | `A344C70F329E366E8ECE00AAC9EF6379A2C0D96321545B4A146C1444D521948F` |
| 测试服务器 | `http://127.0.0.1:8899/` |
| 浏览器 | Playwright CLI Chromium，headless |
| DPR | 1 |
| Git 基线 | `main@875d80d16b9e57e830b7bf77b5ea231a5a283928` |
| PR #14 候选头 | `dev/v6.7-treasure-resonance@c7d69c41640c41110c076f99d42d44174ff19da2` |

测试副本只增加了 `window.__gateGame`、`window.__gatePhase`、`window.__gateResonancePaths` 三个测试入口，未修改产品逻辑；该副本和 harness 不进入 Git 提交。

## 2. Golden Scene 结果

### A：启动与主视觉

- 已有证据：冷启动进入菜单、点击开始进入运行时；固定视口截图已生成。
- 已测视口：`1920x1080`、`1440x900`、`390x844`。
- 观察：页面可加载；Console 仅记录 Three.js deprecated warning 和 favicon 404，未见应用运行时异常。
- 阻断：页面主视觉仍显示“曙光猎人”，与正式产品名“曙光问道”不一致；正式身份门禁不通过。

### B：常规战斗与路径共鸣

- Fixture：42 个高生命普通/精英敌人、5 级武器、两条共鸣场、投射物和命中特效。
- 已有证据：`golden-B-active-combat.png`、指标条目 `B_active_combat`。
- 限制：通过测试 harness 注入，当前版本没有产品内置的可复现 Golden Scene 入口；因此只作为基线样本，不视为最终验收。

### C：高密度压力场

- Fixture：96 个高生命敌人、多个武器、8 个共鸣场、持续效果、危险区和投射物。
- 已有证据：`golden-C-high-density.png`、指标条目 `C_high_density`。
- 结果：本次 headless RAF 样本平均帧时间 6.073ms，P95 8.4ms；这些结果不能替代 60Hz 实机和重启生命周期验证。

### D：Boss 预警与阶段反馈

- Fixture：Boss“金翅鹏王”、Boss 血条、阶段标签、7 个危险区、事件 Banner 和玩家技能。
- 已有证据：`golden-D-boss-telegraph.png`、指标条目 `D_boss_telegraph`。
- 限制：Boss 阶段标签在截图前由 harness 设定；尚未证明完整真实战斗路径下的预警先于伤害、阶段切换和清理逻辑均稳定。

## 3. 实测指标

单位：帧时间为 ms；`materials` 是 scene traversal 得到的唯一材质对象数，不是 `renderer.info` 原生字段；`dt` 运行时未暴露，记录为 `NOT_EXPOSED`。

| Scene | Viewport | Avg ms | FPS | P95 ms | Calls | Triangles | Geometries | Textures | Materials | Children | Enemies | Projectiles | Effects | Hazards |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| A menu | 1920x1080 | 4.166 | 240.03 | 4.3 | 86 | 19,419 | 196 | 2 | 42 | 106 | 0 | 0 | 0 | 0 |
| A menu | 1440x900 | 4.164 | 240.13 | 4.2 | 86 | 19,419 | 196 | 2 | 42 | 106 | 0 | 0 | 0 | 0 |
| A mobile | 390x844 | 4.166 | 240.03 | 4.3 | 75 | 19,211 | 196 | 2 | 42 | 106 | 0 | 0 | 0 | 0 |
| B combat | 1440x900 | 4.447 | 224.85 | 4.3 | 493 | 30,403 | 601 | 2 | 160 | 187 | 42 | 4 | 21 | 0 |
| C high density | 1440x900 | 6.073 | 164.67 | 8.4 | 887 | 50,106 | 953 | 2 | 309 | 325 | 96 | 8 | 74 | 3 |
| D Boss | 1440x900 | 5.224 | 191.43 | 4.2 | 222 | 25,012 | 330 | 2 | 102 | 160 | 17 | 2 | 21 | 7 |

完整 JSON：`E:\shuguang_visual_gate_v1\baseline_metrics.json`。

### 指标解释

- FPS 由 `requestAnimationFrame` 间隔换算；headless Chromium 的有效刷新节奏约 240Hz，因此不能直接宣称真实 60Hz 设备性能通过。
- Scene C 的高密度样本是压力基线，不是性能上限，也没有覆盖 3 次冷启动 + 3 次重启后的资源回收。
- `renderer.info.memory.geometries` 和唯一材质数在相同 harness 状态下目前只有单次样本，不能关闭生命周期回归门禁。

## 4. 截图证据

| 场景 | 文件 |
|---|---|
| A 1920 | `E:\shuguang_visual_gate_v1\golden-A-menu-1920.png` |
| A 1440 | `E:\shuguang_visual_gate_v1\golden-A-menu-1440.png` |
| A mobile | `E:\shuguang_visual_gate_v1\golden-A-menu-mobile.png` |
| B combat | `E:\shuguang_visual_gate_v1\golden-B-active-combat.png` |
| C high density | `E:\shuguang_visual_gate_v1\golden-C-high-density.png` |
| D Boss | `E:\shuguang_visual_gate_v1\golden-D-boss-telegraph.png` |

## 5. 当前门禁判定

| 门禁 | 判定 | 证据/原因 |
|---|---|---|
| 启动 | PARTIAL | 本地浏览器可进入菜单和开始运行；尚未完成 3 次冷启动/3 次开始的正式记录 |
| 身份 | BLOCKED | 主视觉仍出现“曙光猎人”，正式名要求为“曙光问道” |
| 视口 | PASS（当前样本） | `390x844` 的 `scrollWidth=390`，固定截图已生成；尚未覆盖所有交互点击 |
| 动画/状态 | BLOCKED | 暂停后打开 Codex 会同时出现暂停层与 Codex；关闭动作会被暂停层拦截 |
| 战斗可读性 | PARTIAL | B/C/D 压力图已生成；未完成正式用户路径和多轮截图审查 |
| 60Hz 性能 | BLOCKED | 当前为 headless 高刷新节奏，缺少 60Hz 固定环境实测 |
| 资源稳定性 | BLOCKED | `clearRuntime()` 未清理武器 Mesh/Group；重启后生命周期回归未通过 |
| Console | PARTIAL | 未见应用异常；存在 Three.js deprecated warning 与 favicon 404，需在最终证据中区分应用错误和非应用噪声 |
| 证据完整性 | PARTIAL | A/B/C/D 截图和单次指标已具备；缺少正式可复现 fixture、重启矩阵和 60Hz 记录 |

## 6. 阻断项清单

1. **身份阻断**：可见标题/角色身份仍是“曙光猎人”，与本阶段正式名不一致。
2. **生命周期阻断**：武器 Blade/Aura/Raven 创建的 Mesh/Group 不在 `clearRuntime()` 中统一清理；重复开始会把旧对象留在 scene 中。
3. **状态机阻断**：暂停状态打开 Codex 后两个 overlay 可并存，Codex 关闭会被暂停层拦截，且关闭逻辑固定回到 PLAY。
4. **正式性能证据阻断**：目前指标来自 headless harness 单次样本；没有 60Hz 固定环境、3 次重启和前后计数对照。
5. **视觉一致性阻断**：旧暗色 CSS 与后续亮色 CSS 同时存在，当前虽然最终计算样式偏亮，但主题层级尚未收敛为一套可维护规范。
6. **视觉反馈风险**：高频 trail 路径持续新建 Geometry/Material/Mesh；这会污染 Scene C 与长时间运行的资源基线。

## 7. 本轮代码变更

- Git 提交只新增：`docs/VISUAL_QUALITY_GATE_V1.md`、`docs/VISUAL_BASELINE_V1.md`。
- 未修改 `D:\1\曙光猎人_V6.7.2_启动修复版.html`。
- 未新增玩法、武器、Boss、地图、法宝、路径或大型 VFX。
- 未修改现有运行时生命周期、状态机或 CSS。

## 8. 已知限制

- 本地 HTML 通过 CDN 加载 Three.js/GSAP；离线、CDN 失败和真实移动设备尚未纳入本次基线。
- B/C/D 的注入 harness 位于 `E:\shuguang_visual_gate_v1`，没有提交到产品仓库；复现需要同一测试副本和浏览器条件。
- 当前没有把 V6.7.2 单文件纳入 Git 分支，因此 Git 分支只能承载门禁文档，不能视为 PR #14 运行时修复。
- 本次只建立第一版基线，未使用主观“更好看”“更流畅”作为通过依据。

## 9. 下一步建议

1. 先关闭身份、状态机和武器 Mesh 生命周期阻断，再重新采集 A/B/C/D。
2. 增加只在测试构建启用的 Golden Scene 入口或可复现脚本，保持产品运行时不引入调试 UI。
3. 在固定 60Hz 环境和至少一个真实移动设备上重跑帧时间/资源矩阵。
4. 对同一状态做冷启动 3 次、开始 3 次、重启 3 次，对比 geometries、materials、scene children 和截图。
5. 门禁达到 PASS 后，再由 GitHub PR 进行合并审查；本基线不启动 V6.8 设计。
