#!/usr/bin/env python3
"""Run the complete deterministic V8 release gate in one command."""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

BASE_COMMANDS = [
    ("runtime-build", ["tools/build_runtime_v6_7.py", "--check"]),
    ("v68-realm", ["tools/test_v68_realm.py"]),
    ("v70-weapon", ["tools/test_v70_weapon.py"]),
    ("v71-motion", ["tools/test_v71_motion.py"]),
    ("v72-boss", ["tools/test_v72_boss.py"]),
    ("v73-run-closure", ["tools/test_v73_run_closure.py"]),
    ("v80-release-gate", ["tools/test_v80_release_gate.py"]),
    ("v81-spirit-vein", ["tools/test_v81_spirit_vein.py"]),
    ("v8-resonance-paths", ["tools/test_v8_resonance_paths.py"]),
    ("v8-balance-contract", ["tools/test_v8_balance.py"]),
    ("v8-evidence-contract", ["tools/test_v8_evidence_review.py"]),
    ("v8-package-contract", ["tools/test_v8_package.py"]),
]

PROFILE_COMMANDS = [
    ("high-density-profile", ["tools/profile_high_density.py", "--frames", "600"]),
    ("realm-rule-profile", ["tools/profile_v68_rules.py", "--frames", "600"]),
]
RETRYABLE_BROWSER_GATES = {
    "v68-realm", "v70-weapon", "v71-motion", "v72-boss", "v73-run-closure",
    "v80-release-gate", "v81-spirit-vein", "v8-resonance-paths", "high-density-profile", "realm-rule-profile",
}


def run_command(name: str, command: list[str], timeout: int) -> dict[str, object]:
    started = time.perf_counter()
    env = os.environ.copy()
    env["PYTHONIOENCODING"] = "utf-8"
    result = subprocess.run(
        [sys.executable, *command],
        cwd=ROOT,
        env=env,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=timeout,
    )
    return {
        "name": name,
        "command": [sys.executable, *command],
        "returncode": result.returncode,
        "passed": result.returncode == 0,
        "elapsed_seconds": round(time.perf_counter() - started, 3),
        "stdout_tail": result.stdout[-2000:],
        "stderr_tail": result.stderr[-2000:],
    }


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--with-profiles", action="store_true", help="also run the two 600-frame performance profiles")
    parser.add_argument("--output", type=Path, help="write the gate summary JSON")
    parser.add_argument("--timeout", type=int, default=240, help="per-command timeout in seconds")
    args = parser.parse_args()

    commands = BASE_COMMANDS + (PROFILE_COMMANDS if args.with_profiles else [])
    results: list[dict[str, object]] = []
    for name, command in commands:
        attempts = 2 if name in RETRYABLE_BROWSER_GATES else 1
        result = None
        for attempt in range(attempts):
            try:
                result = run_command(name, command, args.timeout)
            except subprocess.TimeoutExpired as exc:
                result = {
                    "name": name,
                    "command": [sys.executable, *command],
                    "returncode": 124,
                    "passed": False,
                    "elapsed_seconds": args.timeout,
                    "stdout_tail": str(exc.stdout or "")[-2000:],
                    "stderr_tail": str(exc.stderr or "")[-2000:],
                    "error": "timeout",
                }
            if result["passed"] or attempt + 1 >= attempts:
                break
            time.sleep(1)
        assert result is not None
        results.append(result)
        print(json.dumps({"name": name, "passed": result["passed"], "attempts": attempt + 1,
                          "elapsed_seconds": result["elapsed_seconds"]}, ensure_ascii=False))
        if not result["passed"]:
            break

    summary = {
        "passed": len(results) == len(commands) and all(result["passed"] for result in results),
        "with_profiles": args.with_profiles,
        "results": results,
    }
    rendered = json.dumps(summary, ensure_ascii=False, indent=2)
    print(rendered)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(rendered + "\n", encoding="utf-8")
    return 0 if summary["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
