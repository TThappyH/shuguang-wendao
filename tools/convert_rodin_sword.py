#!/usr/bin/env python3
"""Convert a Rodin OBJ texture pack into one self-contained Godot GLB.

Run with Blender, for example:
  blender --background --python tools/convert_rodin_sword.py -- \
    --source output/rodin_sword_raw \
    --output godot/assets/weapons/qingyao_flying_sword/qingyao_flying_sword_v1.glb

The script intentionally preserves source geometry.  It only assembles the
provided PBR textures, aligns the sword with the gameplay convention, and
normalizes its overall length.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--length", type=float, default=2.2)
    return parser.parse_args(argv)


def reset_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.materials, bpy.data.images):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def load_image(path: Path, *, non_color: bool = False) -> bpy.types.Image:
    image = bpy.data.images.load(str(path.resolve()), check_existing=True)
    if non_color:
        image.colorspace_settings.name = "Non-Color"
    return image


def image_node(nodes, path: Path, label: str, *, non_color: bool = False):
    node = nodes.new("ShaderNodeTexImage")
    node.name = label
    node.label = label
    node.image = load_image(path, non_color=non_color)
    return node


def build_material(source: Path) -> bpy.types.Material:
    material = bpy.data.materials.new("QingyaoFlyingSword_MattePBR")
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    nodes.clear()

    output = nodes.new("ShaderNodeOutputMaterial")
    output.location = (760, 0)
    shader = nodes.new("ShaderNodeBsdfPrincipled")
    shader.location = (420, 0)
    shader.inputs["Metallic"].default_value = 0.0
    shader.inputs["Roughness"].default_value = 0.72
    shader.inputs["Specular IOR Level"].default_value = 0.24
    links.new(shader.outputs["BSDF"], output.inputs["Surface"])

    diffuse = image_node(nodes, source / "texture_diffuse.png", "Base Color")
    diffuse.location = (-520, 220)
    links.new(diffuse.outputs["Color"], shader.inputs["Base Color"])

    roughness = image_node(
        nodes, source / "texture_roughness.png", "Roughness", non_color=True
    )
    roughness.location = (-520, -40)
    links.new(roughness.outputs["Color"], shader.inputs["Roughness"])

    metallic = image_node(
        nodes, source / "texture_metallic.png", "Metallic", non_color=True
    )
    metallic.location = (-520, -220)
    links.new(metallic.outputs["Color"], shader.inputs["Metallic"])

    normal_texture = image_node(
        nodes, source / "texture_normal.png", "Normal", non_color=True
    )
    normal_texture.location = (-520, -420)
    normal_map = nodes.new("ShaderNodeNormalMap")
    normal_map.location = (80, -360)
    normal_map.inputs["Strength"].default_value = 0.28
    links.new(normal_texture.outputs["Color"], normal_map.inputs["Color"])
    links.new(normal_map.outputs["Normal"], shader.inputs["Normal"])

    return material


def import_and_prepare(source: Path, material: bpy.types.Material, target_length: float):
    bpy.ops.wm.obj_import(filepath=str((source / "base.obj").resolve()))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError("Rodin OBJ contains no mesh objects")

    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    sword = bpy.context.view_layer.objects.active
    sword.name = "QingyaoFlyingSwordV1"

    sword.data.materials.clear()
    sword.data.materials.append(material)
    for polygon in sword.data.polygons:
        polygon.use_smooth = True

    # Rodin presents the sword tip along +Y.  Gameplay treats the launch
    # direction as local -Z, matching the previous procedural sword.
    sword.rotation_euler.x = math.radians(-90.0)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)

    dimensions = sword.dimensions
    longest = max(dimensions)
    if longest <= 1.0e-6:
        raise RuntimeError("Rodin sword has empty bounds")
    scale = target_length / longest
    sword.scale = Vector((scale, scale, scale))
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

    corners = [sword.matrix_world @ Vector(corner) for corner in sword.bound_box]
    minimum = Vector((min(v.x for v in corners), min(v.y for v in corners), min(v.z for v in corners)))
    maximum = Vector((max(v.x for v in corners), max(v.y for v in corners), max(v.z for v in corners)))
    sword.location -= (minimum + maximum) * 0.5
    bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)
    return sword


def mesh_report(sword: bpy.types.Object, output: Path) -> dict:
    sword.data.calc_loop_triangles()
    corners = [sword.matrix_world @ Vector(corner) for corner in sword.bound_box]
    minimum = Vector((min(v.x for v in corners), min(v.y for v in corners), min(v.z for v in corners)))
    maximum = Vector((max(v.x for v in corners), max(v.y for v in corners), max(v.z for v in corners)))
    return {
        "asset": "qingyao_flying_sword_v1",
        "vertices": len(sword.data.vertices),
        "triangles": len(sword.data.loop_triangles),
        "materials": len(sword.data.materials),
        "bounds_min": list(minimum),
        "bounds_max": list(maximum),
        "dimensions": list(maximum - minimum),
        "output": str(output.resolve()),
        "output_bytes": output.stat().st_size,
        "geometry_preserved": True,
    }


def main() -> None:
    args = parse_args()
    source = args.source.resolve()
    output = args.output.resolve()
    report_path = (args.report or output.with_suffix(".report.json")).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    reset_scene()
    material = build_material(source)
    sword = import_and_prepare(source, material, args.length)

    bpy.ops.object.select_all(action="DESELECT")
    sword.select_set(True)
    bpy.context.view_layer.objects.active = sword
    bpy.ops.export_scene.gltf(
        filepath=str(output),
        export_format="GLB",
        use_selection=True,
        export_materials="EXPORT",
        export_image_format="AUTO",
        export_yup=True,
    )

    report = mesh_report(sword, output)
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False))


if __name__ == "__main__":
    main()
