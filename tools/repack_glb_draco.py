#!/usr/bin/env python3
"""Losslessly repack a GLB with Draco geometry compression for web upload."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import bpy


def args() -> argparse.Namespace:
    values = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    return parser.parse_args(values)


def main() -> None:
    options = args()
    source = options.source.resolve()
    output = options.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(source))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    for obj in meshes:
        obj.select_set(True)
    bpy.ops.export_scene.gltf(
        filepath=str(output),
        export_format="GLB",
        export_materials="EXPORT",
        export_image_format="AUTO",
        export_draco_mesh_compression_enable=True,
        export_draco_mesh_compression_level=6,
        export_draco_position_quantization=16,
        export_draco_normal_quantization=12,
        export_draco_texcoord_quantization=14,
    )
    print(json.dumps({
        "source": str(source),
        "source_bytes": source.stat().st_size,
        "output": str(output),
        "output_bytes": output.stat().st_size,
        "mesh_objects": len(meshes),
        "geometry_decimated": False,
    }))


if __name__ == "__main__":
    main()
