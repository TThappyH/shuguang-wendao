import json
import sys
from pathlib import Path

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree


def main() -> None:
    separator = sys.argv.index("--") if "--" in sys.argv else len(sys.argv)
    source = Path(sys.argv[separator + 1]).resolve()
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(source))
    mesh_object = next(obj for obj in bpy.context.scene.objects if obj.type == "MESH")
    tree = BVHTree.FromObject(mesh_object, bpy.context.evaluated_depsgraph_get())
    samples = {}
    for x, y in ((0, 0), (0, 2), (0, -2), (2, 0), (-2, 0), (5, 5), (-5, -5)):
        location, normal, face_index, distance = tree.ray_cast(Vector((x, y, 100.0)), Vector((0, 0, -1)), 200.0)
        samples[f"{x},{y}"] = None if location is None else {"height": location.z, "face": face_index, "normal": list(normal)}
    print("MAP_SURFACE=" + json.dumps(samples))


if __name__ == "__main__":
    main()
