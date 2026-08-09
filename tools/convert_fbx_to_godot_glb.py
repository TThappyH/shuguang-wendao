import sys
from pathlib import Path

import bpy
from mathutils import Vector


def reset_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def world_bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
    points = [obj.matrix_world @ Vector(corner) for obj in objects for corner in obj.bound_box]
    minimum = Vector(tuple(min(point[index] for point in points) for index in range(3)))
    maximum = Vector(tuple(max(point[index] for point in points) for index in range(3)))
    return minimum, maximum


def main() -> None:
    separator = sys.argv.index("--") if "--" in sys.argv else len(sys.argv)
    arguments = sys.argv[separator + 1 :]
    if len(arguments) != 2:
        raise SystemExit("usage: blender --background --python convert_fbx_to_godot_glb.py -- SOURCE.fbx OUTPUT.glb")

    source = Path(arguments[0]).resolve()
    output = Path(arguments[1]).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)

    reset_scene()
    bpy.ops.import_scene.fbx(filepath=str(source), use_anim=False)
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError(f"no mesh imported from {source}")

    minimum, maximum = world_bounds(meshes)
    center = (minimum + maximum) * 0.5
    offset = Vector((-center.x, -center.y, -minimum.z))
    for obj in meshes:
        obj.location += offset
        obj.name = "Qingyao_Base"
        obj.data.name = "Qingyao_BaseMesh"
        obj.select_set(True)

    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.export_scene.gltf(
        filepath=str(output),
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_apply=True,
        export_normals=True,
        export_tangents=False,
        export_materials="EXPORT",
        export_animations=False,
        export_cameras=False,
        export_lights=False,
    )
    print(f"CHARACTER_EXPORT={output}")


if __name__ == "__main__":
    main()
