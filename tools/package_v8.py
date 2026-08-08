#!/usr/bin/env python3
"""Create and verify the reproducible local V8 playable package."""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
import zipfile
from pathlib import Path
from zipfile import ZipInfo

ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ROOT / "runtime" / "v6.7"
BUILD_TOOL = ROOT / "tools" / "build_runtime_v6_7.py"
PACKAGE_SCHEMA = "shuguang-wendao.v8-package.v1"
FIXED_ZIP_DATE = (2020, 1, 1, 0, 0, 0)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def git_value(*args: str, fallback: str = "UNKNOWN") -> str:
    try:
        return subprocess.check_output(
            ["git", *args], cwd=ROOT, text=True, stderr=subprocess.DEVNULL
        ).strip() or fallback
    except (OSError, subprocess.CalledProcessError):
        return fallback


def run_build_check() -> None:
    result = subprocess.run(
        [sys.executable, str(BUILD_TOOL), "--check"],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    if result.returncode:
        raise RuntimeError(
            "runtime build check failed\n"
            + (result.stdout or "")
            + (result.stderr or "")
        )


def runtime_files() -> list[str]:
    manifest_path = RUNTIME / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    files = ["runtime/v6.7/manifest.json"]
    files.extend(f"runtime/v6.7/{item['file']}" for item in manifest["chunks"]["items"])
    return files


def package_files() -> list[str]:
    files = [
        "index.html",
        "README.md",
        "CHANGELOG.md",
        "runtime-source/v6.7.html",
        "docs/V8_RELEASE_GATE.md",
        "docs/V8_BALANCE_REVIEW.md",
        "docs/V8_HUMAN_TEST.md",
        "tools/validate_v8_run_record.py",
        "tools/review_v8_evidence.py",
        "assets/characters/qingyao/model_v1/qingyao_v1.glb",
    ]
    files.extend(runtime_files())
    return files


def collect_records(files: list[str]) -> list[dict[str, object]]:
    records: list[dict[str, object]] = []
    for relative in sorted(files):
        path = ROOT / relative
        if not path.is_file():
            raise FileNotFoundError(f"required package file missing: {relative}")
        content = path.read_bytes()
        records.append({"path": relative, "bytes": len(content), "sha256": sha256(content)})
    return records


def make_manifest(records: list[dict[str, object]]) -> dict[str, object]:
    return {
        "schema": PACKAGE_SCHEMA,
        "product": "曙光问道",
        "version": "V8.1 spirit vein encounters",
        "branch": git_value("branch", "--show-current"),
        "git_head": git_value("rev-parse", "HEAD"),
        "entry": "index.html",
        "runtime_manifest": "runtime/v6.7/manifest.json",
        "requires_http_server": True,
        "requires_network_for_cdn": True,
        "notes": [
            "This package contains the current playable V8 foundation snapshot.",
            "Balance is still a human-review gate; the package does not claim balance completion.",
        ],
        "files": records,
    }


def write_fixed_zip(output: Path, records: list[dict[str, object]], manifest: dict[str, object]) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for record in records:
            relative = str(record["path"])
            info = ZipInfo(relative, date_time=FIXED_ZIP_DATE)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 0
            info.external_attr = 0o644 << 16
            archive.writestr(info, (ROOT / relative).read_bytes())
        info = ZipInfo("PACKAGE_MANIFEST.json", date_time=FIXED_ZIP_DATE)
        info.compress_type = zipfile.ZIP_DEFLATED
        info.create_system = 0
        info.external_attr = 0o644 << 16
        archive.writestr(
            info,
            (json.dumps(manifest, ensure_ascii=False, indent=2) + "\n").encode("utf-8"),
        )


def verify_package(output: Path) -> dict[str, object]:
    with zipfile.ZipFile(output, "r") as archive:
        names = archive.namelist()
        manifest = json.loads(archive.read("PACKAGE_MANIFEST.json").decode("utf-8"))
        expected = {record["path"] for record in manifest["files"]}
        actual = set(names) - {"PACKAGE_MANIFEST.json"}
        if actual != expected:
            raise RuntimeError(f"package entries mismatch: expected={sorted(expected)} actual={sorted(actual)}")
        for record in manifest["files"]:
            content = archive.read(str(record["path"]))
            if len(content) != record["bytes"] or sha256(content) != record["sha256"]:
                raise RuntimeError(f"package hash mismatch: {record['path']}")
    return {"output": str(output), "entries": len(names), "bytes": output.stat().st_size}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, help="ZIP path; defaults to releases/v8-foundation-<HEAD>.zip")
    parser.add_argument("--skip-build-check", action="store_true", help="skip the canonical runtime check")
    args = parser.parse_args()

    if not args.skip_build_check:
        run_build_check()
    records = collect_records(package_files())
    manifest = make_manifest(records)
    output = args.output or (ROOT / "releases" / f"v8.1-spirit-vein-{manifest['git_head'][:12]}.zip")
    write_fixed_zip(output, records, manifest)
    print(json.dumps(verify_package(output), ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
