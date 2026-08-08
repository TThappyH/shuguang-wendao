#!/usr/bin/env python3
"""Small deterministic contract test for the V8 run-record reviewer."""
from __future__ import annotations

from validate_v8_run_record import analyze


def complete_fixture() -> dict:
    return {
        "schema": "shuguang-wendao.run.v1",
        "realmState": {"breakthroughCount": 5, "activeRealmRules": ["a", "b", "c", "d", "e"]},
        "runRecord": {
            "serial": 1,
            "status": "BOSS_CLEARED",
            "result": "BOSS_CLEARED",
            "elapsed": 900,
            "levelUps": 8,
            "levelChoices": [{"id": "bolt"}],
            "realmChoices": [{"ruleId": str(i)} for i in range(5)],
            "bosses": [
                {"index": i, "name": f"boss-{i}", "spawnTime": i * 100, "defeatedAt": i * 100 + 20}
                for i in range(6)
            ],
            "kills": 120,
            "damageDealt": 12000,
            "damageTaken": 300,
        },
    }


def main() -> int:
    good = analyze(complete_fixture())
    assert good["passed"] and good["status"] == "COMPLETE_RUN_EVIDENCE"
    assert good["balance_decision"] == "DATA_READY_FOR_HUMAN_REVIEW"
    assert good["metrics"]["bosses_defeated"] == 6
    partial = complete_fixture()
    partial["runRecord"]["status"] = "DEAD"
    partial["runRecord"]["damageTaken"] = 0
    result = analyze(partial)
    assert result["passed"] and result["status"] == "PARTIAL_RUN_EVIDENCE"
    assert result["balance_decision"] == "NEEDS_MORE_RUN_DATA"
    print("PASS: complete and partial run-record contracts")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
