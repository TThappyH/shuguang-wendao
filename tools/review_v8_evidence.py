#!/usr/bin/env python3
"""Review a folder of exported V8 run records for the first balance gate."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from validate_v8_run_record import analyze


def record_paths(inputs: list[Path]) -> list[Path]:
    found: set[Path] = set()
    for item in inputs:
        if item.is_dir():
            found.update(path for path in item.rglob("shuguang-wendao-run-*.json") if path.is_file())
        elif item.is_file():
            found.add(item)
    return sorted(found)


def review(paths: list[Path]) -> dict[str, Any]:
    records: list[dict[str, Any]] = []
    errors: list[str] = []
    for path in paths:
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            errors.append(f"{path}: {exc}")
            continue
        result = analyze(payload)
        records.append({
            "path": str(path),
            "status": result["status"],
            "balance_decision": result["balance_decision"],
            "errors": result["errors"],
            "warnings": result["warnings"],
            "metrics": result["metrics"],
        })
        if not result["passed"]:
            errors.extend(f"{path}: {message}" for message in result["errors"])

    complete = [record for record in records if record["status"] == "COMPLETE_RUN_EVIDENCE"]
    deaths = [record for record in records if record["metrics"].get("run_status") == "DEAD"]
    ready = bool(records) and not errors and bool(complete) and bool(deaths)
    return {
        "passed": ready,
        "decision": "READY_FOR_FIRST_BALANCE_REVIEW" if ready else "NEEDS_MORE_RUN_DATA",
        "requirements": {
            "records": len(records),
            "complete_runs": len(complete),
            "death_runs": len(deaths),
            "all_records_schema_valid": not errors,
        },
        "errors": errors,
        "records": records,
        "note": "双样本门禁只确认有通关与死亡证据，不代表数值平衡通过。",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="+", type=Path, help="导出的 JSON 文件或存放记录的目录")
    parser.add_argument("--require-both", action="store_true", help="要求至少一份通关和一份死亡记录")
    parser.add_argument("--output", type=Path, help="同时写出复盘摘要 JSON")
    args = parser.parse_args()
    paths = record_paths(args.paths)
    result = review(paths)
    rendered = json.dumps(result, ensure_ascii=False, indent=2)
    print(rendered)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered + "\n", encoding="utf-8")
    if args.require_both and not result["passed"]:
        return 3
    return 0 if not result["errors"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
