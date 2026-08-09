import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def reset_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.materials, bpy.data.images, bpy.data.armatures, bpy.data.actions):
        for datablock in list(datablocks):
            datablocks.remove(datablock)


def import_asset(path: Path) -> None:
    suffix = path.suffix.lower()
    if suffix == ".fbx":
        bpy.ops.import_scene.fbx(filepath=str(path), use_anim=True)
    elif suffix == ".obj":
        bpy.ops.wm.obj_import(filepath=str(path))
    elif suffix in {".glb", ".gltf"}:
        bpy.ops.import_scene.gltf(filepath=str(path))
    else:
        raise ValueError(f"unsupported asset: {path}")


def inspect(path: Path) -> dict:
    reset_scene()
    import_asset(path)
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    armatures = [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
    vertices = sum(len(obj.data.vertices) for obj in meshes)
    polygons = sum(len(obj.data.polygons) for obj in meshes)
    triangles = 0
    world_points = []
    for obj in meshes:
        obj.data.calc_loop_triangles()
        triangles += len(obj.data.loop_triangles)
        world_points.extend(obj.matrix_world @ Vector(corner) for corner in obj.bound_box)
    if world_points:
        minimum = [min(point[index] for point in world_points) for index in range(3)]
        maximum = [max(point[index] for point in world_points) for index in range(3)]
        dimensions = [maximum[index] - minimum[index] for index in range(3)]
    else:
        minimum = maximum = dimensions = [0.0, 0.0, 0.0]
    vertex_heights = sorted(
        (obj.matrix_world @ vertex.co).z
        for obj in meshes
        for vertex in obj.data.vertices
    )
    height_quantiles = {
        str(percentile): vertex_heights[min(len(vertex_heights) - 1, int((len(vertex_heights) - 1) * percentile / 100.0))]
        for percentile in (10, 25, 50, 75, 90, 95, 99)
    } if vertex_heights else {}
    return {
        "path": str(path),
        "objects": len(bpy.context.scene.objects),
        "mesh_objects": len(meshes),
        "vertices": vertices,
        "polygons": polygons,
        "triangles": triangles,
        "materials": [
            {
                "name": material.name,
                "diffuse_color": list(material.diffuse_color),
                "use_nodes": material.use_nodes,
                "nodes": [node.bl_idname for node in material.node_tree.nodes] if material.use_nodes else [],
            }
            for material in bpy.data.materials
        ],
        "images": [{"name": image.name, "filepath": image.filepath, "packed": image.packed_file is not None} for image in bpy.data.images],
        "armatures": [{"name": armature.name, "bones": len(armature.data.bones)} for armature in armatures],
        "actions": [action.name for action in bpy.data.actions],
        "bounds_min": minimum,
        "bounds_max": maximum,
        "dimensions": dimensions,
        "height_quantiles": height_quantiles,
        "object_names": [obj.name for obj in bpy.context.scene.objects],
        "uv_layers": {obj.name: [layer.name for layer in obj.data.uv_layers] for obj in meshes},
        "color_attributes": {obj.name: [layer.name for layer in obj.data.color_attributes] for obj in meshes},
    }


def main() -> None:
    separator = sys.argv.index("--") if "--" in sys.argv else len(sys.argv)
    paths = [Path(value).resolve() for value in sys.argv[separator + 1 :]]
    results = [inspect(path) for path in paths]
    print("CHARACTER_INSPECTION=" + json.dumps(results, ensure_ascii=False))


if __name__ == "__main__":
    main()
