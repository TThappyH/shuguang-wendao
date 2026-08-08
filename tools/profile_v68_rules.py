#!/usr/bin/env python3
"""V6.8 worst-case active-rule FAST LOOP profile."""
from __future__ import annotations

import argparse
import json
import socket
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JS = ROOT / "tools" / "profile_v68_rules_browser.js"


def free_port() -> int:
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


def decode(stdout: str) -> dict:
    for line in reversed([x.strip() for x in stdout.splitlines() if x.strip()]):
        try:
            value = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(value, str):
            try:
                value = json.loads(value)
            except json.JSONDecodeError:
                continue
        if isinstance(value, dict) and "whole_frame" in value:
            return value
    raise RuntimeError(f"Playwright CLI did not return profile JSON: {stdout[-2000:]}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--frames", type=int, default=600)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    port = free_port()
    server = subprocess.Popen([sys.executable, "-m", "http.server", str(port), "--bind", "127.0.0.1"],
                              cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    session = f"v68rules_{server.pid}"
    base = ["npx.cmd", "--yes", "--package", "@playwright/cli", "playwright-cli", "--session", session]
    url = f"http://127.0.0.1:{port}/index.html?test=realm"
    script_path = None
    try:
        time.sleep(.25)
        script = JS.read_text(encoding="utf-8").replace("__PROFILE_URL__", url).replace("__PROFILE_FRAMES__", str(args.frames))
        with tempfile.NamedTemporaryFile("w", suffix=".js", encoding="utf-8", delete=False) as handle:
            handle.write(script)
            script_path = Path(handle.name)
        opened = subprocess.run(base + ["open", url], cwd=ROOT, capture_output=True, text=True,
                                encoding="utf-8", errors="replace", timeout=120)
        if opened.returncode:
            raise RuntimeError(opened.stdout + opened.stderr)
        run = subprocess.run(base + ["run-code", "--filename", str(script_path), "--raw"], cwd=ROOT,
                             capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=max(180, args.frames // 2 + 180))
        if run.returncode:
            raise RuntimeError(run.stdout + run.stderr)
        result = decode(run.stdout)
        result["gate"] = {"threshold_ms": 16.667, "passed": result["whole_frame"]["p95"] <= 16.667}
        output = args.output or (ROOT / "evidence" / f"profile_v68_rules_{args.frames}.json")
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
        print(json.dumps({"output": str(output), "frames": args.frames, "p95_ms": result["whole_frame"]["p95"],
                          "p99_ms": result["whole_frame"]["p99"], "active_rules": result["active_rule_count"],
                          "hook_calls_per_frame": result["hook_calls_per_frame"], "passed": result["gate"]["passed"]}, ensure_ascii=False))
        return 0 if result["gate"]["passed"] else 1
    finally:
        subprocess.run(base + ["close"], cwd=ROOT, capture_output=True, text=True,
                       encoding="utf-8", errors="replace", timeout=20)
        server.terminate()
        try:
            server.wait(timeout=5)
        except subprocess.TimeoutExpired:
            server.kill()
        if script_path:
            script_path.unlink(missing_ok=True)


if __name__ == "__main__":
    raise SystemExit(main())
