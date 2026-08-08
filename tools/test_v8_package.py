#!/usr/bin/env python3
"""Deterministic contract test for the V8 playable release package."""
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE_TOOL = ROOT / "tools" / "package_v8.py"


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="shuguang-v8-package-") as temp:
        output = Path(temp) / "v8-foundation-test.zip"
        result = subprocess.run(
            [sys.executable, str(PACKAGE_TOOL), "--output", str(output)],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
        if result.returncode:
            raise AssertionError(result.stdout + result.stderr)
        with zipfile.ZipFile(output, "r") as archive:
            manifest = json.loads(archive.read("PACKAGE_MANIFEST.json").decode("utf-8"))
            assert manifest["schema"] == "shuguang-wendao.v8-package.v1"
            assert manifest["entry"] == "index.html"
            assert manifest["requires_http_server"] is True
            assert manifest["requires_network_for_cdn"] is True
            paths = {record["path"] for record in manifest["files"]}
            names = set(archive.namelist())
            assert "index.html" in paths
            assert "runtime/v6.7/manifest.json" in paths
            assert "assets/characters/qingyao/model_v1/qingyao_v1.glb" in paths
            assert names == paths | {"PACKAGE_MANIFEST.json"}
            assert archive.read("index.html")
            assert archive.read("assets/characters/qingyao/model_v1/qingyao_v1.glb")[:4] == b"glTF"
    print("PASS: V8 release package contents and readback")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
