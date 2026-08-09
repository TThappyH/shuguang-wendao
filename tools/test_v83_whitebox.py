#!/usr/bin/env python3
"""V8.3 Qingyao asset lock and whitebox map-framework browser gate."""
from __future__ import annotations

import argparse
import hashlib
import json
import socket
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
JS = ROOT / "tools" / "test_v83_whitebox_browser.js"
SOURCE_MODEL = Path(r"D:\1\fantasy swordsman 3d model.glb")
GAME_MODEL = ROOT / "assets" / "characters" / "qingyao" / "model_v1" / "qingyao_v1.glb"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


def decode(stdout: str) -> dict:
    for line in reversed([line.strip() for line in stdout.splitlines() if line.strip()]):
        try:
            value = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(value, str):
            try:
                value = json.loads(value)
            except json.JSONDecodeError:
                continue
        if isinstance(value, dict) and "passed" in value:
            return value
    raise RuntimeError(f"Playwright CLI did not return test JSON: {stdout[-2000:]}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=0)
    args = parser.parse_args()
    if not SOURCE_MODEL.is_file() or not GAME_MODEL.is_file():
        print(json.dumps({"passed": False, "failures": ["Qingyao source or game GLB is missing"]}, ensure_ascii=False))
        return 1
    source_hash = sha256(SOURCE_MODEL)
    game_hash = sha256(GAME_MODEL)
    if source_hash != game_hash:
        print(json.dumps({"passed": False, "failures": ["Qingyao GLB hash mismatch"], "sourceHash": source_hash, "gameHash": game_hash}, ensure_ascii=False))
        return 1
    port = args.port or free_port()
    server = subprocess.Popen(
        [sys.executable, "-m", "http.server", str(port), "--bind", "127.0.0.1"],
        cwd=ROOT,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    session = f"v83whitebox_{server.pid}"
    base = ["npx.cmd", "--yes", "--package", "@playwright/cli", "playwright-cli", "--session", session]
    url = f"http://127.0.0.1:{port}/index.html?test=v83-whitebox"
    script_path = None
    try:
        time.sleep(.25)
        script = JS.read_text(encoding="utf-8").replace("__TEST_URL__", url)
        with tempfile.NamedTemporaryFile("w", suffix=".js", encoding="utf-8", delete=False) as handle:
            handle.write(script)
            script_path = Path(handle.name)
        opened = subprocess.run(base + ["open", url], cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=120)
        if opened.returncode:
            raise RuntimeError(opened.stdout + opened.stderr)
        run = subprocess.run(base + ["run-code", "--filename", str(script_path), "--raw"], cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=180)
        if run.returncode:
            raise RuntimeError(run.stdout + run.stderr)
        result = decode(run.stdout)
        result["sourceHash"] = source_hash
        result["gameHash"] = game_hash
        result["assetHashMatch"] = source_hash == game_hash
        print(json.dumps(result, ensure_ascii=False))
        return 0 if result.get("passed") else 1
    finally:
        subprocess.run(base + ["close"], cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=20)
        server.terminate()
        try:
            server.wait(timeout=5)
        except subprocess.TimeoutExpired:
            server.kill()
        if script_path:
            script_path.unlink(missing_ok=True)


if __name__ == "__main__":
    raise SystemExit(main())
