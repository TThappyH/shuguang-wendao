# V8 首轮平衡复盘

## 使用方式

1. 在结算页点击「导出本局记录」。
2. 将 JSON 放到任意本地目录。
3. 在仓库根目录执行：

```powershell
python tools/validate_v8_run_record.py PATH\TO\shuguang-wendao-run-*.json --require-complete
```

## 工具会确认

- 记录版本与字段完整。
- 6 个 Boss 是否都有生成/击败时间。
- 5 次境界突破与道途选择是否存在。
- 升级选择、击杀、造成伤害、承受伤害是否存在。
- 是否达到 `DATA_READY_FOR_HUMAN_REVIEW`。

## 第一轮只记录，不立即改数值

每份记录先保留以下指标：

- 用时与每个 Boss 的战斗时长。
- 升级选择与道途组成。
- `damage_per_minute`。
- `damage_taken_per_minute`。
- `damage_per_kill`。
- 结算状态：`BOSS_CLEARED` 或 `DEAD`。

至少收集一份完整通关记录和一份死亡记录后，再讨论敌人血量、接触伤害、生成节奏或 Boss 技能冷却。工具输出的 `DATA_READY_FOR_HUMAN_REVIEW` 只代表证据齐全，不代表平衡已经通过。
