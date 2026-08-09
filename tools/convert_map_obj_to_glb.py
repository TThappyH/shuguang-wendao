import sys
from pathlib import Path

import bpy
from mathutils import Vector


TARGET_DIAMETER = 78.0


def reset_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
    points = [obj.matrix_world @ Vector(corner) for obj in objects for corner in obj.bound_box]
    minimum = Vector(tuple(min(point[index] for point in points) for index in range(3)))
    maximum = Vector(tuple(max(point[index] for point in points) for index in range(3)))
    return minimum, maximum


def image_texture(nodes: bpy.types.Nodes, path: Path, color_space: str) -> bpy.types.ShaderNodeTexImage:
    node = nodes.new("ShaderNodeTexImage")
    node.image = bpy.data.images.load(str(path), check_existing=True)
    node.image.colorspace_settings.name = color_space
    node.interpolation = "Linear"
    return node


def build_material(asset_dir: Path) -> bpy.types.Material:
    material = bpy.data.materials.new("Shuguang_Map_PBR")
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    nodes.clear()

    output = nodes.new("ShaderNodeOutputMaterial")
    shader = nodes.new("ShaderNodeBsdfPrincipled")
    shader.inputs["Roughness"].default_value = 0.72
    links.new(shader.outputs["BSDF"], output.inputs["Surface"])

    diffuse = image_texture(nodes, asset_dir / "texture_diffuse.png", "sRGB")
    links.new(diffuse.outputs["Color"], shader.inputs["Base Color"])

    roughness = image_texture(nodes, asset_dir / "texture_roughness.png", "Non-Color")
    links.new(roughness.outputs["Color"], shader.inputs["Roughness"])

    metallic = image_texture(nodes, asset_dir / "texture_metallic.png", "Non-Color")
    links.new(metallic.outputs["Color"], shader.inputs["Metallic"])

    normal_texture = image_texture(nodes, asset_dir / "texture_normal.png", "Non-Color")
    normal_map = nodes.new("ShaderNodeNormalMap")
    normal_map.inputs["Strength"].default_value = 0.75
    links.new(normal_texture.outputs["Color"], normal_map.inputs["Color"])
    links.new(normal_map.outputs["Normal"], shader.inputs["Normal"])
    return material


def look_at(obj: bpy.types.Object, target: Vector) -> None:
    obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Y").to_euler()


def render_preview(output: Path) -> None:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = 1024
    scene.render.resolution_y = 768
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.filepath = str(output)

    world = bpy.data.worlds.new("PreviewWorld")
    world.use_nodes = True
    background = next(node for node in world.node_tree.nodes if node.bl_idname == "ShaderNodeBackground")
    background.inputs["Color"].default_value = (0.32, 0.40, 0.40, 1.0)
    background.inputs["Strength"].default_value = 0.5
    scene.world = world

    camera_data = bpy.data.cameras.new("MapPreviewCamera")
    camera = bpy.data.objects.new("MapPreviewCamera", camera_data)
    scene.collection.objects.link(camera)
    camera.location = Vector((82.0, -94.0, 108.0))
    camera_data.lens = 62.0
    look_at(camera, Vector((0.0, 0.0, 12.0)))
    scene.camera = camera

    sun_data = bpy.data.lights.new("Sun", "SUN")
    sun_data.energy = 2.4
    sun_data.color = (1.0, 0.88, 0.72)
    sun = bpy.data.objects.new("Sun", sun_data)
    sun.rotation_euler = (0.62, -0.48, -0.35)
    scene.collection.objects.link(sun)

    area_data = bpy.data.lights.new("JadeFill", "AREA")
    area_data.energy = 1200.0
    area_data.color = (0.50, 0.82, 0.78)
    area_data.shape = "DISK"
    area_data.size = 34.0
    area = bpy.data.objects.new("JadeFill", area_data)
    area.location = Vector((-18.0, -10.0, 42.0))
    look_at(area, Vector((0.0, 0.0, 0.0)))
    scene.collection.objects.link(area)
    bpy.ops.render.render(write_still=True)


def main() -> None:
    separator = sys.argv.index("--") if "--" in sys.argv else len(sys.argv)
    arguments = sys.argv[separator + 1 :]
    if len(arguments) not in {2, 3}:
        raise SystemExit("usage: blender --background --python convert_map_obj_to_glb.py -- ASSET_DIR OUTPUT.glb [PREVIEW.png]")

    asset_dir = Path(arguments[0]).resolve()
    output = Path(arguments[1]).resolve()
    preview = Path(arguments[2]).resolve() if len(arguments) == 3 else None
    output.parent.mkdir(parents=True, exist_ok=True)
    if preview:
        preview.parent.mkdir(parents=True, exist_ok=True)

    reset_scene()
    bpy.ops.wm.obj_import(filepath=str(asset_dir / "base.obj"))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError("map OBJ contains no mesh")

    material = build_material(asset_dir)
    minimum, maximum = bounds(meshes)
    horizontal_size = max(maximum.x - minimum.x, maximum.y - minimum.y)
    scale_factor = TARGET_DIAMETER / horizontal_size
    center = (minimum + maximum) * 0.5

    for obj in meshes:
        obj.data.materials.clear()
        obj.data.materials.append(material)
        obj.location += Vector((-center.x, -center.y, -minimum.z))
        obj.scale = Vector((1.0, 1.0, 1.0)) * scale_factor
        obj.name = "Shuguang_External_Map"
        obj.data.name = "Shuguang_External_MapMesh"
        obj.select_set(True)

    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    if preview:
        render_preview(preview)

    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.export_scene.gltf(
        filepath=str(output),
        export_format="GLB",
        use_selection=True,
        export_yup=True,
        export_apply=True,
        export_normals=True,
        export_tangents=True,
        export_materials="EXPORT",
        export_animations=False,
        export_cameras=False,
        export_lights=False,
    )
    print(f"MAP_EXPORT={output}")
    print(f"MAP_SCALE={scale_factor}")


if __name__ == "__main__":
    main()
