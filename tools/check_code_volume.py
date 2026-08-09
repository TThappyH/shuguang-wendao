#!/usr/bin/env python3
"""Enforce the production-code volume floor without counting generated output."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MIN_PRODUCTION_CHARACTERS = 200_000
PRODUCTION_SOURCES = (
    "runtime-source/v6.7.html",
    "tools/build_runtime_v6_7.py",
    "tools/package_v8.py",
    "tools/validate_v8_run_record.py",
    "tools/review_v8_evidence.py",
)


def inspect_source(relative: str) -> dict[str, object]:
    path = ROOT / relative
    if not path.is_file():
        raise FileNotFoundError(f"production source missing: {relative}")
    content = path.read_text(encoding="utf-8")
    return {
        "path": relative,
        "characters": len(content),
        "lines": len(content.splitlines()),
        "sha256": hashlib.sha256(content.encode("utf-8")).hexdigest().upper(),
    }


def build_report(minimum: int) -> dict[str, object]:
    files = [inspect_source(relative) for relative in PRODUCTION_SOURCES]
    characters = sum(int(item["characters"]) for item in files)
    lines = sum(int(item["lines"]) for item in files)
    return {
        "schema": "shuguang-wendao.code-volume.v1",
        "minimum_characters": minimum,
        "production_characters": characters,
        "production_lines": lines,
        "passed": characters >= minimum,
        "exclusions": [
            "runtime generated chunks",
            "binary assets",
            "evidence and screenshots",
            "release archives",
            "cache directories",
        ],
        "files": files,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--minimum", type=int, default=MIN_PRODUCTION_CHARACTERS)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    report = build_report(args.minimum)
    rendered = json.dumps(report, ensure_ascii=False, indent=2)
    print(rendered)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered + "\n", encoding="utf-8")
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
