#!/usr/bin/env python3
"""Apply the approved cool/matte Qingyun texture pass without changing geometry."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import bpy


def parse_args() -> argparse.Namespace:
    values = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--diffuse", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    return parser.parse_args(values)


def main() -> None:
    args = parse_args()
    source = args.source.resolve()
    diffuse_path = args.diffuse.resolve()
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(source))
    diffuse = bpy.data.images.load(str(diffuse_path), check_existing=False)
    diffuse.name = "texture_diffuse"

    edited_materials = 0
    for material in bpy.data.materials:
        if not material.use_nodes:
            continue
        nodes = material.node_tree.nodes
        links = material.node_tree.links
        shader = next((node for node in nodes if node.bl_idname == "ShaderNodeBsdfPrincipled"), None)
        if shader is None:
            continue
        base_input = shader.inputs.get("Base Color")
        if base_input and base_input.is_linked:
            texture = base_input.links[0].from_node
            if texture.bl_idname == "ShaderNodeTexImage":
                texture.image = diffuse
        for input_name, value in (("Metallic", 0.04), ("Roughness", 0.82)):
            socket = shader.inputs.get(input_name)
            if socket is None:
                continue
            for link in list(socket.links):
                links.remove(link)
            socket.default_value = value
        specular = shader.inputs.get("Specular IOR Level")
        if specular is not None:
            specular.default_value = 0.22
        for node in nodes:
            if node.bl_idname == "ShaderNodeNormalMap":
                node.inputs["Strength"].default_value = 0.26
        edited_materials += 1

    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    triangles = 0
    vertices = 0
    for obj in meshes:
        obj.data.calc_loop_triangles()
        triangles += len(obj.data.loop_triangles)
        vertices += len(obj.data.vertices)

    bpy.ops.export_scene.gltf(
        filepath=str(output),
        export_format="GLB",
        export_materials="EXPORT",
        export_image_format="AUTO",
        export_yup=True,
    )
    print(json.dumps({
        "output": str(output),
        "output_bytes": output.stat().st_size,
        "mesh_objects": len(meshes),
        "vertices": vertices,
        "triangles": triangles,
        "edited_materials": edited_materials,
        "geometry_decimated": False,
        "metallic": 0.04,
        "roughness": 0.82,
        "normal_strength": 0.26,
    }))


if __name__ == "__main__":
    main()
