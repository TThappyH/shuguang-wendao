#!/usr/bin/env python3
"""Deterministic V6.7 high-density FAST LOOP gate."""
from __future__ import annotations

import argparse
import json
import os
import socket
import subprocess
import sys
import tempfile
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
JS = ROOT / "tools" / "profile_high_density_browser.js"


def free_port() -> int:
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


def decode_cli_output(stdout: str) -> dict:
    lines = [line.strip() for line in stdout.splitlines() if line.strip()]
    for line in reversed(lines):
        try:
            value = json.loads(line)
            if isinstance(value, str):
                value = json.loads(value)
            if isinstance(value, dict) and "whole_frame" in value:
                return value
        except json.JSONDecodeError:
            continue
    raise RuntimeError(f"Playwright CLI did not return profile JSON: {stdout[-2000:]}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--frames", type=int, default=600)
    parser.add_argument("--port", type=int, default=0)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.frames < 1:
        raise SystemExit("--frames must be positive")

    port = args.port or free_port()
    server = subprocess.Popen([sys.executable, "-m", "http.server", str(port), "--bind", "127.0.0.1"],
                              cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    session = f"v67fast_{os.getpid()}"
    env = os.environ.copy()
    env.update({"PROFILE_URL": f"http://127.0.0.1:{port}/index.html?profile=fast",
               "PROFILE_FRAMES": str(args.frames)})
    try:
        time.sleep(.25)
        base = ["npx.cmd", "--yes", "--package", "@playwright/cli", "playwright-cli", "--session", session]
        script_text = JS.read_text(encoding="utf-8").replace("__PROFILE_URL__", env["PROFILE_URL"]).replace(
            "__PROFILE_FRAMES__", str(args.frames))
        with tempfile.NamedTemporaryFile("w", suffix=".js", encoding="utf-8", delete=False) as handle:
            handle.write(script_text)
            script_path = Path(handle.name)
        opened = subprocess.run(base + ["open", env["PROFILE_URL"]], cwd=ROOT, env=env,
                                capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=120)
        if opened.returncode:
            raise RuntimeError(opened.stdout + opened.stderr)
        run = subprocess.run(base + ["run-code", "--filename", str(script_path), "--raw"], cwd=ROOT, env=env,
                             capture_output=True, text=True, encoding="utf-8", errors="replace",
                             timeout=max(120, args.frames // 2 + 120))
        if run.returncode:
            raise RuntimeError(run.stdout + run.stderr)
        result = decode_cli_output(run.stdout)
        result["gate"] = {"threshold_ms": 16.667, "passed": result["whole_frame"]["p95"] <= 16.667}
        output = args.output or (ROOT / "evidence" / f"profile_high_density_{int(time.time())}.json")
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
        print(json.dumps({"output": str(output), "frames": args.frames,
                          "p95_ms": result["whole_frame"]["p95"],
                          "p99_ms": result["whole_frame"]["p99"],
                          "spikes": result["spike_count"], "passed": result["gate"]["passed"]}, ensure_ascii=False))
        return 0 if result["gate"]["passed"] else 1
    finally:
        subprocess.run(base + ["close"], cwd=ROOT, env=env, capture_output=True, text=True,
                       encoding="utf-8", errors="replace", timeout=20)
        server.terminate()
        try:
            server.wait(timeout=5)
        except subprocess.TimeoutExpired:
            server.kill()
        if "script_path" in locals():
            script_path.unlink(missing_ok=True)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except subprocess.TimeoutExpired as exc:
        print(f"profile timeout: {exc}", file=sys.stderr)
        raise SystemExit(2)
    except Exception as exc:
        print(f"profile failed: {exc}", file=sys.stderr)
        raise SystemExit(2)
