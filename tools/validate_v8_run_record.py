#!/usr/bin/env python3
"""Validate a downloaded V8 run record and emit a balance-review summary.

This tool does not declare the game balanced. It only verifies that a human run
contains enough evidence for the first numerical review.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


EXPECTED_BOSSES = 6
EXPECTED_BREAKTHROUGHS = 5
REQUIRED_RUN_FIELDS = {
    "serial",
    "status",
    "result",
    "elapsed",
    "levelUps",
    "levelChoices",
    "realmChoices",
    "bosses",
    "bossRewardChoices",
    "spiritVeins",
    "maxCombo",
    "kills",
    "damageDealt",
    "damageTaken",
}


def number(value: Any, default: float = 0.0) -> float:
    return float(value) if isinstance(value, (int, float)) else default


def analyze(payload: dict[str, Any]) -> dict[str, Any]:
    errors: list[str] = []
    warnings: list[str] = []
    if payload.get("schema") != "shuguang-wendao.run.v1":
        errors.append("schema must be shuguang-wendao.run.v1")

    run = payload.get("runRecord")
    realm = payload.get("realmState")
    if not isinstance(run, dict):
        errors.append("runRecord is missing")
        run = {}
    if not isinstance(realm, dict):
        errors.append("realmState is missing")
        realm = {}
    missing = sorted(REQUIRED_RUN_FIELDS - set(run))
    if missing:
        errors.append("runRecord missing fields: " + ", ".join(missing))

    bosses = run.get("bosses") if isinstance(run.get("bosses"), list) else []
    defeated = [b for b in bosses if isinstance(b, dict) and b.get("defeatedAt") is not None]
    boss_durations = []
    for boss in defeated:
        spawn = number(boss.get("spawnTime"))
        end = number(boss.get("defeatedAt"))
        if end < spawn:
            errors.append(f"boss {boss.get('index', '?')} defeatedAt precedes spawnTime")
        else:
            boss_durations.append({"index": boss.get("index"), "name": boss.get("name"), "duration": end - spawn})

    elapsed = number(run.get("elapsed"))
    damage_dealt = number(run.get("damageDealt"))
    damage_taken = number(run.get("damageTaken"))
    kills = number(run.get("kills"))
    level_choices = run.get("levelChoices") if isinstance(run.get("levelChoices"), list) else []
    level_up_events = run.get("levelUpEvents") if isinstance(run.get("levelUpEvents"), list) else []
    realm_choices = run.get("realmChoices") if isinstance(run.get("realmChoices"), list) else []
    boss_reward_choices = run.get("bossRewardChoices") if isinstance(run.get("bossRewardChoices"), list) else []
    spirit_veins = run.get("spiritVeins") if isinstance(run.get("spiritVeins"), list) else []
    spirit_veins_captured = [v for v in spirit_veins if isinstance(v, dict) and v.get("status") == "CAPTURED"]
    active_rules = realm.get("activeRealmRules") if isinstance(realm.get("activeRealmRules"), list) else []
    status = run.get("status", "UNKNOWN")
    level_ups = number(run.get("levelUps"))
    complete_evidence = (
        status == "BOSS_CLEARED"
        and len(defeated) == EXPECTED_BOSSES
        and number(realm.get("breakthroughCount")) == EXPECTED_BREAKTHROUGHS
        and len(realm_choices) >= EXPECTED_BREAKTHROUGHS
        and elapsed > 0
        and level_ups > 0
        and len(level_up_events) >= level_ups
        and len(level_choices) > 0
        and len(boss_reward_choices) >= EXPECTED_BOSSES
        and len(spirit_veins) > 0
        and number(run.get("maxCombo")) > 0
        and damage_dealt > 0
        and damage_taken > 0
    )

    if status == "DEAD":
        warnings.append("本局以死亡结束；可用于生存压力分析，不作为完整通关样本。")
    if len(defeated) < len(bosses):
        warnings.append(f"Boss 记录中有 {len(bosses) - len(defeated)} 个未击败节点。")
    if damage_taken <= 0:
        warnings.append("damageTaken 为 0；走位/受伤压力数据不足。")
    if not level_choices:
        warnings.append("没有升级选择记录；构筑成长数据不足。")
    if level_ups > len(level_up_events):
        warnings.append("levelUpEvents 少于 levelUps；升级事件账本不完整。")
    if status == "BOSS_CLEARED" and len(boss_reward_choices) < EXPECTED_BOSSES:
        warnings.append("Boss 奖励选择少于 6 次；首领机缘取舍数据不足。")
    if not spirit_veins:
        warnings.append("没有灵脉争夺记录；战场目标与路线选择数据不足。")
    elif not spirit_veins_captured:
        warnings.append("灵脉争夺均未完成；需要检查目标风险与收益是否失衡。")
    if elapsed <= 0:
        warnings.append("elapsed 为 0；时间曲线数据不足。")

    return {
        "passed": not errors,
        "status": "COMPLETE_RUN_EVIDENCE" if complete_evidence else "PARTIAL_RUN_EVIDENCE",
        "errors": errors,
        "warnings": warnings,
        "metrics": {
            "run_serial": run.get("serial"),
            "run_status": status,
            "elapsed_seconds": elapsed,
            "bosses_recorded": len(bosses),
            "bosses_defeated": len(defeated),
            "boss_durations": boss_durations,
            "boss_reward_choices": len(boss_reward_choices),
            "spirit_veins": len(spirit_veins),
            "spirit_veins_captured": len(spirit_veins_captured),
            "spirit_vein_capture_rate": round(len(spirit_veins_captured) / max(len(spirit_veins), 1), 3),
            "max_combo": run.get("maxCombo", 0),
            "breakthroughs": realm.get("breakthroughCount", 0),
            "realm_choices": len(realm_choices),
            "active_rules": len(active_rules),
            "level_ups": run.get("levelUps", 0),
            "level_up_events": len(level_up_events),
            "level_choices": len(level_choices),
            "kills": kills,
            "damage_dealt": damage_dealt,
            "damage_taken": damage_taken,
            "damage_per_minute": round(damage_dealt / max(elapsed / 60.0, 1e-9), 3),
            "damage_taken_per_minute": round(damage_taken / max(elapsed / 60.0, 1e-9), 3),
            "damage_per_kill": round(damage_dealt / max(kills, 1), 3),
        },
        "balance_decision": "DATA_READY_FOR_HUMAN_REVIEW" if complete_evidence else "NEEDS_MORE_RUN_DATA",
        "note": "这是证据完整性判定，不是数值平衡通过判定。",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("record", type=Path, help="导出的 shuguang-wendao-run-*.json")
    parser.add_argument("--require-complete", action="store_true", help="要求完整通关证据，否则返回非零")
    args = parser.parse_args()
    try:
        payload = json.loads(args.record.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(json.dumps({"passed": False, "errors": [str(exc)]}, ensure_ascii=False))
        return 2
    result = analyze(payload)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    if not result["passed"]:
        return 2
    if args.require_complete and result["status"] != "COMPLETE_RUN_EVIDENCE":
        return 3
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
