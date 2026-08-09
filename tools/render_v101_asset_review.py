#!/usr/bin/env python3
"""Render neutral V10.1 review plates for Qingyao and his flying sword."""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def parse_args() -> argparse.Namespace:
    values = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--character", required=True, type=Path)
    parser.add_argument("--sword", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    return parser.parse_args(values)


def reset_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in list(bpy.data.collections):
        if collection.users == 0:
            bpy.data.collections.remove(collection)


def setup_render() -> bpy.types.Object:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 1024
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.world.color = (0.62, 0.62, 0.60)

    world = scene.world
    world.use_nodes = True
    background = world.node_tree.nodes.get("Background")
    background.inputs["Color"].default_value = (0.64, 0.63, 0.60, 1.0)
    background.inputs["Strength"].default_value = 0.48

    bpy.ops.object.light_add(type="AREA", location=(3.5, -4.0, 6.0))
    key = bpy.context.object
    key.name = "NeutralKey"
    key.data.energy = 850.0
    key.data.shape = "DISK"
    key.data.size = 4.0

    bpy.ops.object.light_add(type="AREA", location=(-4.0, -1.0, 3.5))
    fill = bpy.context.object
    fill.name = "NeutralFill"
    fill.data.energy = 520.0
    fill.data.size = 5.0

    bpy.ops.object.light_add(type="AREA", location=(0.0, 4.0, 5.0))
    rim = bpy.context.object
    rim.name = "NeutralRim"
    rim.data.energy = 680.0
    rim.data.size = 3.5

    bpy.ops.object.camera_add()
    camera = bpy.context.object
    camera.data.lens = 58.0
    scene.camera = camera
    return camera


def point_camera(camera: bpy.types.Object, position: tuple[float, float, float], target: tuple[float, float, float]) -> None:
    camera.location = Vector(position)
    direction = Vector(target) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def imported_meshes(path: Path) -> list[bpy.types.Object]:
    existing = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(path.resolve()))
    return [obj for obj in bpy.context.scene.objects if obj not in existing and obj.type == "MESH"]


def normalize_to_floor(meshes: list[bpy.types.Object]) -> None:
    points = [obj.matrix_world @ Vector(corner) for obj in meshes for corner in obj.bound_box]
    minimum = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    maximum = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    offset = Vector((-(minimum.x + maximum.x) * 0.5, -(minimum.y + maximum.y) * 0.5, -minimum.z))
    for obj in meshes:
        obj.location += offset


def ground_plane() -> None:
    bpy.ops.mesh.primitive_plane_add(size=12.0, location=(0.0, 0.0, -0.012))
    plane = bpy.context.object
    material = bpy.data.materials.new("ReviewGround")
    material.diffuse_color = (0.58, 0.58, 0.55, 1.0)
    material.roughness = 0.94
    plane.data.materials.append(material)


def render(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.context.scene.render.filepath = str(path.resolve())
    bpy.ops.render.render(write_still=True)


def render_character(character: Path, output: Path) -> None:
    reset_scene()
    camera = setup_render()
    meshes = imported_meshes(character)
    normalize_to_floor(meshes)
    ground_plane()
    point_camera(camera, (0.0, -4.2, 1.20), (0.0, 0.0, 1.02))
    render(output / "01_qingyao_front.png")
    point_camera(camera, (2.2, -3.0, 7.35), (0.0, 0.0, 0.95))
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 3.45
    render(output / "02_qingyao_gameplay_60deg.png")


def render_sword(sword_path: Path, output: Path) -> None:
    reset_scene()
    camera = setup_render()
    meshes = imported_meshes(sword_path)
    normalize_to_floor(meshes)
    sword = meshes[0]
    sword.location.z -= 1.1
    sword.rotation_euler = (math.radians(4.0), math.radians(-12.0), math.radians(-18.0))
    point_camera(camera, (3.0, -5.2, 1.4), (0.0, 0.0, 0.0))
    camera.data.lens = 72.0
    render(output / "03_sword_closeup.png")

    left = sword.copy()
    left.data = sword.data
    bpy.context.collection.objects.link(left)
    right = sword.copy()
    right.data = sword.data
    bpy.context.collection.objects.link(right)
    sword.location = Vector((0.0, 0.0, 0.18))
    left.location = Vector((-0.62, 0.0, -0.02))
    right.location = Vector((0.62, 0.0, -0.02))
    left.rotation_euler.y += math.radians(-8.0)
    right.rotation_euler.y += math.radians(8.0)
    point_camera(camera, (3.6, -6.4, 2.3), (0.0, 0.0, 0.05))
    camera.data.lens = 66.0
    render(output / "04_three_sword_formation.png")


def main() -> None:
    args = parse_args()
    render_character(args.character, args.output)
    render_sword(args.sword, args.output)


if __name__ == "__main__":
    main()
