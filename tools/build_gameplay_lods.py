"""Build deterministic gameplay LOD GLBs with Blender.

Run with:
  blender --background --python tools/build_gameplay_lods.py -- INPUT OUTPUT TARGET_TRIS

The source asset is never modified. Materials, UVs and object transforms are retained.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import bpy


def arguments() -> tuple[Path, Path, int]:
    if "--" not in sys.argv:
        raise SystemExit("Expected: -- INPUT OUTPUT TARGET_TRIS")
    values = sys.argv[sys.argv.index("--") + 1 :]
    if len(values) != 3:
        raise SystemExit("Expected exactly INPUT OUTPUT TARGET_TRIS")
    return Path(values[0]).resolve(), Path(values[1]).resolve(), int(values[2])


def triangle_count(mesh: bpy.types.Mesh) -> int:
    mesh.calc_loop_triangles()
    return len(mesh.loop_triangles)


def scene_triangles() -> int:
    return sum(triangle_count(obj.data) for obj in bpy.context.scene.objects if obj.type == "MESH")


def main() -> None:
    source, destination, target = arguments()
    if not source.is_file():
        raise SystemExit(f"Missing source asset: {source}")
    if target < 100:
        raise SystemExit("TARGET_TRIS must be at least 100")

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    before = scene_triangles()
    if before <= 0:
        raise SystemExit("Imported scene contains no triangles")

    ratio = min(1.0, target / before)
    for obj in meshes:
        # Very small decorative meshes are kept intact; the bulk meshes absorb reduction.
        count = triangle_count(obj.data)
        if count < 128 or ratio >= 0.999:
            continue
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        modifier = obj.modifiers.new(name="GameplayLOD", type="DECIMATE")
        modifier.decimate_type = "COLLAPSE"
        modifier.ratio = max(0.001, ratio)
        modifier.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=modifier.name)
        obj.select_set(False)

    after = scene_triangles()
    destination.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(destination),
        export_format="GLB",
        export_apply=True,
        export_yup=True,
        export_materials="EXPORT",
        export_texcoords=True,
        export_normals=True,
        export_tangents=True,
        export_attributes=False,
        export_cameras=False,
        export_lights=False,
        export_animations=False,
    )
    report = {
        "source": str(source),
        "output": str(destination),
        "target_triangles": target,
        "source_triangles": before,
        "output_triangles": after,
        "ratio": after / before,
        "mesh_count": len(meshes),
    }
    report_path = destination.with_suffix(destination.suffix + ".report.json")
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print("LOD_BUILD=" + json.dumps(report, separators=(",", ":")))


if __name__ == "__main__":
    main()
