#!/usr/bin/env python3
"""Deterministic contract test for the V8 two-sample evidence gate."""
from __future__ import annotations

import json
import tempfile
from pathlib import Path

from review_v8_evidence import record_paths, review


def base_record(status: str, result: str, defeated: int, breakthroughs: int, damage_taken: float) -> dict:
    return {
        "schema": "shuguang-wendao.run.v1",
        "realmState": {
            "breakthroughCount": breakthroughs,
            "activeRealmRules": [str(i) for i in range(breakthroughs)],
        },
        "runRecord": {
            "serial": 1,
            "status": status,
            "result": result,
            "elapsed": 900,
            "levelUps": 4,
            "levelUpEvents": [{"level": i + 2, "openedAt": i * 120} for i in range(4)],
            "levelChoices": [{"id": "might"}],
            "realmChoices": [{"ruleId": str(i)} for i in range(breakthroughs)],
            "bosses": [
                {
                    "index": i,
                    "name": f"boss-{i}",
                    "spawnTime": i * 100,
                    "defeatedAt": i * 100 + 20 if i < defeated else None,
                }
                for i in range(6)
            ],
            "kills": 80,
            "damageDealt": 9000,
            "damageTaken": damage_taken,
        },
    }


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="shuguang-v8-evidence-") as temp:
        root = Path(temp)
        complete = root / "shuguang-wendao-run-1-boss_cleared.json"
        death = root / "shuguang-wendao-run-2-dead.json"
        complete.write_text(json.dumps(base_record("BOSS_CLEARED", "BOSS_CLEARED", 6, 5, 240)), encoding="utf-8")
        death.write_text(json.dumps(base_record("DEAD", "PLAYER_DEAD", 2, 0, 120)), encoding="utf-8")
        (root / "review.json").write_text("{}", encoding="utf-8")
        assert record_paths([root]) == sorted([complete, death])
        result = review([complete, death])
        assert result["passed"]
        assert result["decision"] == "READY_FOR_FIRST_BALANCE_REVIEW"
        assert result["requirements"] == {
            "records": 2,
            "complete_runs": 1,
            "death_runs": 1,
            "all_records_schema_valid": True,
        }
        incomplete = review([complete])
        assert not incomplete["passed"]
        assert incomplete["decision"] == "NEEDS_MORE_RUN_DATA"
    print("PASS: V8 complete/death evidence review contract")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
