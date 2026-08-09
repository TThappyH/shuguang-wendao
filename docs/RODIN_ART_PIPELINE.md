# Rodin Art Pipeline（Creator / 非 API）

## 链路

```text
Rodin Creator 网页
→ 官方 RodinBridge
→ 本机 Blender
→ 清理 / Rig / 动画 / LOD / 碰撞
→ GLB
→ Godot assets
→ assets/rodin/manifest.json
```

运行时只识别逻辑槽位，不把具体文件名写死在角色、敌人和地图逻辑中。更换 Rodin 资产时，更新 `manifest.json` 的 `path` 即可。

## 正式槽位

| Slot | 用途 | 目标三角面 | 硬上限 | 材质上限 |
| --- | --- | ---: | ---: | ---: |
| `qingyao_player` | 青曜 | 50k | 70k | 6 |
| `qingyun_island` | 青云山麓关卡块 | 180k | 300k | 12 |
| `enemy_stalker` | 逐影 | 18k | 30k | 4 |
| `enemy_skirmisher` | 游煞 | 16k | 26k | 4 |
| `enemy_bulwark` | 镇岳 | 24k | 38k | 4 |

## 导入要求

- 单位：米；角色脚底落在原点；正面朝 Godot 约定方向。
- 人物、马尾、分片下摆保留可绑定区域；飞剑不并入角色 Mesh。
- 角色纹理默认不超过 2K；大场景应拆块并准备 LOD/遮挡层。
- 导出前应用 Transform、检查法线、移除隐藏重复 Mesh、保留清晰命名。
- 有骨骼资产优先 FBX 进入 Blender，Godot 最终使用 GLB。
- Rodin 只负责美术生产；碰撞、敌人状态、伤害与掉落仍由 Godot Gameplay Actor 控制。

## 当前资产状态

- 当前青曜：`824,537 vertices / 999,998 triangles`。
- 当前青云岛：`896,791 vertices / 999,992 triangles`。
- 两者暂时标记 `prototype_exempt=true`，可以继续做视觉验证，但不是最终性能资产。
- 三个敌人 Rodin 槽位尚为空；运行时会使用明确标记的原型占位体，资产到位后无需重写 AI。

完成 Smart Low-Poly 与高模法线烘焙后，应移除 `prototype_exempt`，让资产门禁开始严格失败。
