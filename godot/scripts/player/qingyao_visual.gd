class_name QingyaoVisual
extends Node3D

const MODEL_ASSET_SLOT: StringName = &"qingyao_player"
const MODEL_FALLBACK_PATH := "res://assets/characters/qingyao/qingyao_v1.glb"
const TARGET_HEIGHT := 2.18

var model_root: Node3D
var loaded := false
var source_mesh_count := 0
var source_vertices := 0
var source_triangles := 0
var loaded_asset_path := ""

func _ready() -> void:
	name = "QingyaoVisual"
	_load_model()

func _load_model() -> void:
	loaded_asset_path = RodinAssetRegistry.asset_path(MODEL_ASSET_SLOT)
	if loaded_asset_path.is_empty():
		loaded_asset_path = MODEL_FALLBACK_PATH
	var resolved := resolve_model_scene(loaded_asset_path, MODEL_FALLBACK_PATH)
	var resource: PackedScene = resolved.scene
	loaded_asset_path = resolved.path
	if resource == null:
		push_error("Qingyao primary and fallback models failed to import")
		return
	model_root = resource.instantiate()
	model_root.name = "QingyaoGLB"
	add_child(model_root)
	_collect_mesh_metrics(model_root)
	RodinAssetRegistry.configure_runtime_geometry(model_root, MODEL_ASSET_SLOT)
	_fit_to_gameplay_scale()
	loaded = true

static func resolve_model_scene(primary_path: String, fallback_path: String) -> Dictionary:
	for candidate in [primary_path, fallback_path]:
		if candidate.is_empty() or not ResourceLoader.exists(candidate, "PackedScene"):
			continue
		var resource := ResourceLoader.load(candidate, "PackedScene")
		if resource is PackedScene:
			return {"scene": resource as PackedScene, "path": candidate}
	return {"scene": null, "path": ""}

func snapshot() -> Dictionary:
	return {
		"loaded": loaded,
		"asset_slot": String(MODEL_ASSET_SLOT),
		"asset_path": loaded_asset_path,
		"meshes": source_mesh_count,
		"vertices": source_vertices,
		"triangles": source_triangles
	}

func _collect_mesh_metrics(root: Node) -> void:
	for child: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		source_mesh_count += 1
		for surface_index in mesh_instance.mesh.get_surface_count():
			var arrays := mesh_instance.mesh.surface_get_arrays(surface_index)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			source_vertices += vertices.size()
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			source_triangles += indices.size() / 3 if not indices.is_empty() else vertices.size() / 3

func _fit_to_gameplay_scale() -> void:
	var bounds := _calculate_bounds(model_root)
	if bounds.size.y <= 0.001:
		push_error("Qingyao model bounds are empty")
		return
	var scale_factor := clampf(TARGET_HEIGHT / bounds.size.y, 0.0005, 20.0)
	model_root.scale = Vector3.ONE * scale_factor
	model_root.position = Vector3(-bounds.get_center().x * scale_factor, -bounds.position.y * scale_factor, -bounds.get_center().z * scale_factor)
	model_root.rotation.y = PI

func _calculate_bounds(root: Node3D) -> AABB:
	var result := AABB()
	var has_bounds := false
	var to_local := root.global_transform.affine_inverse()
	for child: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var local_aabb := mesh_instance.mesh.get_aabb()
		var transform := to_local * mesh_instance.global_transform
		for corner_index in 8:
			var corner := local_aabb.position + Vector3(
				local_aabb.size.x if corner_index & 1 else 0.0,
				local_aabb.size.y if corner_index & 2 else 0.0,
				local_aabb.size.z if corner_index & 4 else 0.0
			)
			var point := transform * corner
			if not has_bounds:
				result = AABB(point, Vector3.ZERO)
				has_bounds = true
			else:
				result = result.expand(point)
	return result
