# Rodin runtime asset slots

`manifest.json` 是 Godot 与 Rodin/Blender 生产链之间的唯一运行时契约。

- 不在 Gameplay 脚本中新增 Rodin 文件硬编码路径。
- 不覆盖旧资产；先导入新版本，再原子更新槽位路径。
- `prototype_exempt` 只用于视觉原型，不代表满足性能预算。
- 导入后运行 `res://tests/asset_contract_test.gd` 和 smoke test。

完整规范见 `E:\shuguang-wendao-v68\docs\RODIN_ART_PIPELINE.md`。
