# 《曙光问道》青云山麓 Visual Slice V0

## 状态

`PASS`：Golden Scene A 完成第一轮视觉跃迁；PR #14 保持冻结，未进入 V6.8。

- Branch: `prototype/qingyun-visual-slice-v0`
- Base: `fb8a9b3e092a9863e45e46aea7026c5bd5db036d`
- Prototype skill: `INSTALLED`
- Prototype runtime: `runtime-source/v6.7.html`

## 目标与固定夹具

目标是让同一机位在 2 秒内读出“青山、云海、灵草、白玉仙门、修士”。

Golden Scene A 固定：camera preset `visual-slice`、seed 由运行时固定夹具继承、UI state 为开局暂停、无战斗对象。证据位于：

- BEFORE: `E:\shuguang_runtime_closure\visual-slice\before-fixed-camera\`
- AFTER: `E:\shuguang_runtime_closure\visual-slice\after-final\`
- B/C: `E:\shuguang_runtime_closure\visual-slice\BC-final\`

## 参考与 License Gate

| Repo | 用途 | License | Code copied? |
|---|---|---|---|
| `SahilK-027/Elemental-Serenity` | Skydome、光照层次、世界编排思路 | MIT | No；inspiration only |
| `achrefelouafi/GrassSystemThreeJS` | 草地 instancing、风场、terrain 思路 | MIT | No；inspiration only |
| `boona13/threejs-grass-water-shaders` | 草地交互、stylized water 思路 | MIT | No；inspiration only |
| `CK42BB/procedural-grass-threejs` | 草地 LOD、风与降级策略 | MIT | No；inspiration only |
| `CK42BB/procedural-clouds-threejs` | 云质量分级思路 | MIT | No；inspiration only |

License 通过 GitHub repository metadata 实查；本分支没有复制外部仓库代码或资源。

## Visual Systems

| System | Result | 实现 |
|---|---|---|
| QingyunSky | PASS | Shader skydome + 天青/地平线/淡金方向光 |
| Lighting | PASS | Key / Fill / Rim 三层关系，降低过曝 |
| Ground | PASS | 青绿基础、石径、留白、局部色块 |
| Mountains | PASS | 3 层低成本 InstancedMesh 远山 + atmospheric fade |
| Landmark | PASS | 白玉青云山门、屋檐、淡金门徽 |
| Grass | PASS | Instanced field，低顶点 blade strip |
| Wind | PASS | Global sway + gust + fine flutter shader bands |
| Grass Push | PASS | player position 更新 `uPush`，局部 push falloff |
| Water | NOT IMPLEMENTED | V0 可选项，避免阻塞第一轮视觉问题 |

Visual slice 使用 compact environment branch；正式战斗 runtime 保留原玩法对象与资源生命周期路径。

## Draw Call / Resource Delta

1440×900、同一 Golden Scene A 固定机位：

| Metric | Before | After | Delta |
|---|---:|---:|---:|
| Draw calls | 86 | 72 | -14 |
| Triangles | 19,419 | 11,439 | -7,980 |
| Geometries | 193 | 71 | -122 |
| Materials | 43 | 31 | -12 |
| Scene children | 170 | 90 | -80 |

环境新增 draw-call 目标 `≤ +12` 通过；prototype fixture 使用 compact batching，未引入持续分配热路径。

## Performance

V6.7 baseline（R2.1 final）：Average `11.723ms` / P95 `15.4ms` / P99 `18.8ms`。

当前完整 high-density runtime：

- FAST LOOP P95：`12.2 / 12.2 / 12.4ms`
- 3000 帧 Average：`11.098ms`
- P95：`13.7ms`
- P99：`15.5ms`
- Max：`23.6ms`
- Gate：`PASS`，P95 `<=16.667ms`

证据：`E:\shuguang_runtime_closure\evidence\qingyun-v0-push-final-3000.json`。

## Golden Scenes

- Golden Scene A: BEFORE / AFTER / Mobile 均已输出；AFTER 明显读出远山、云海、草、白玉山门和修士。
- Golden Scene B: `after_B_COMBAT_1440.png`，43 敌人、3 主武器、2 共鸣场；玩家和战斗区域可读。
- Golden Scene C: `after_C_HIGH_DENSITY_1440.png`，97 敌人、9 武器、8 共鸣场；截图用于可读性记录，性能以固定 3000 帧 profile 为准。

## Visual Self Review

1. AFTER 与 BEFORE 并排：是，构图和层次明显增强。
2. 是否一眼有东方修仙味：是，青绿山水、白玉山门、淡金门徽成立。
3. 是否仍明显是普通 Three.js Demo：不再是纯色 Plane + 几何体组合，但仍是 V0 stylized prototype。
4. 玩家是否是画面主角：是；A 中玩家位于前景中心，B/C 中战斗对象围绕玩家。
5. 环境是否帮助玩法：是；草和远山形成层次，白玉门作为目标地标，没有强 Bloom 压过战斗。

## Adopted / Rejected

- Adopted：shader skydome、低成本云海、三层远山、Instanced grass、三层风、player push、白玉山门。
- Rejected：full volumetric raymarch、SSR、WebGPU-only、强 Bloom、完整 terrain engine、外部仓库代码复制。
- Deferred：青云灵泉/浅溪水面。

## Known Limitations

- Grass blade 当前为 stylized strip，不是最终高质量 GrassSystem。
- 云为 mesh cluster，不是体积云。
- Water 未实现；不阻塞 V0。
- 尚未执行真实移动设备 WebGL 采样；390×844 本地 Chromium smoke 已通过。
- Cloudflare Browser Run 本轮未使用 token；本地 Chromium/Playwright 作为证据来源。
- 这是 throwaway prototype，尚未创建正式视觉 PR，也未向 PR #14 写入视觉代码。
