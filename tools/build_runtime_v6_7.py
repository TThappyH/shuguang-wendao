#!/usr/bin/env python3
"""Build and verify the canonical V6.7 browser runtime package."""
from __future__ import annotations

import argparse
import base64
import gzip
import hashlib
import json
import struct
import zlib
from io import BytesIO
from pathlib import Path

CHUNK_CHARS = 15000
ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "runtime-source" / "v6.7.html"
RUNTIME = ROOT / "runtime" / "v6.7"
MANIFEST = RUNTIME / "manifest.json"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def make_gzip(source: bytes) -> bytes:
    out = BytesIO()
    with gzip.GzipFile(fileobj=out, mode="wb", filename="", mtime=0) as stream:
        stream.write(source)
    return out.getvalue()


def metadata(source: bytes, compressed: bytes, encoded: str, chunks: list[str]) -> dict:
    crc32, isize = struct.unpack("<II", compressed[-8:])
    return {
        "version": "v6.7",
        "source": {
            "path": "runtime-source/v6.7.html",
            "bytes": len(source),
            "sha256": sha256(source),
        },
        "gzip": {
            "bytes": len(compressed),
            "sha256": sha256(compressed),
            "crc32": f"{crc32:08X}",
            "isize": isize,
        },
        "chunks": {
            "count": len(chunks),
            "encoding": "base64-ascii",
            "split_chars": CHUNK_CHARS,
            "concatenated_b64_sha256": sha256(encoded.encode("ascii")),
            "concatenated_gzip_sha256": sha256(base64.b64decode(encoded)),
            "items": [
                {"file": f"gzip-{i:02d}.b64", "chars": len(chunk), "bytes": len(chunk.encode("ascii"))}
                for i, chunk in enumerate(chunks, 1)
            ],
        },
    }


def build() -> dict:
    source = SOURCE.read_bytes()
    compressed = make_gzip(source)
    encoded = base64.b64encode(compressed).decode("ascii")
    chunks = [encoded[i : i + CHUNK_CHARS] for i in range(0, len(encoded), CHUNK_CHARS)]
    RUNTIME.mkdir(parents=True, exist_ok=True)
    for old in RUNTIME.glob("gzip-*.b64"):
        old.unlink()
    for i, chunk in enumerate(chunks, 1):
        (RUNTIME / f"gzip-{i:02d}.b64").write_text(chunk, encoding="ascii", newline="")
    report = metadata(source, compressed, encoded, chunks)
    MANIFEST.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="")
    verify_report = verify()
    if not verify_report["equal"]:
        raise SystemExit(json.dumps(verify_report, ensure_ascii=False, indent=2))
    return verify_report


def verify() -> dict:
    source = SOURCE.read_bytes()
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    parts = []
    for item in manifest["chunks"]["items"]:
        parts.append((RUNTIME / item["file"]).read_text(encoding="ascii").strip())
    encoded = "".join(parts)
    compressed = base64.b64decode(encoded, validate=True)
    result = {
        "source_bytes": len(source),
        "source_sha256": sha256(source),
        "gzip_bytes": len(compressed),
        "gzip_sha256": sha256(compressed),
        "concatenated_b64_sha256": sha256(encoded.encode("ascii")),
        "chunk_count": len(parts),
    }
    try:
        decompressed = gzip.decompress(compressed)
        result.update({
            "decompressed_bytes": len(decompressed),
            "decompressed_sha256": sha256(decompressed),
            "crc32": f"{zlib.crc32(decompressed) & 0xFFFFFFFF:08X}",
            "isize": len(decompressed) & 0xFFFFFFFF,
            "roundtrip": "PASS",
        })
    except Exception as exc:
        result.update({"roundtrip": "FAIL", "error": repr(exc)})
        result["equal"] = False
        return result
    result["equal"] = decompressed == source and result["source_sha256"] == result["decompressed_sha256"]
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="verify existing chunks without rewriting")
    args = parser.parse_args()
    result = verify() if args.check else build()
    print(json.dumps(result, ensure_ascii=False, indent=2))
    if not result.get("equal"):
        raise SystemExit(1)


if __name__ == "__main__":
    main()
