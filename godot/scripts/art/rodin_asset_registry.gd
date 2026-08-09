class_name RodinAssetRegistry
extends RefCounted

const MANIFEST_PATH := "res://assets/rodin/manifest.json"
static var _manifest: Dictionary = {}

static func reload_manifest() -> Dictionary:
	_manifest = {}
	if not FileAccess.file_exists(MANIFEST_PATH):
		push_warning("Rodin asset manifest missing: %s" % MANIFEST_PATH)
		return _manifest
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		push_warning("Rodin asset manifest could not be opened")
		return _manifest
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_manifest = parsed
	else:
		push_warning("Rodin asset manifest is invalid JSON")
	return _manifest

static func manifest() -> Dictionary:
	if _manifest.is_empty():
		reload_manifest()
	return _manifest

static func slot(slot_id: StringName) -> Dictionary:
	var assets: Dictionary = manifest().get("assets", {})
	return assets.get(String(slot_id), {}) as Dictionary

static func asset_path(slot_id: StringName) -> String:
	return String(slot(slot_id).get("path", ""))

static func has_asset(slot_id: StringName) -> bool:
	var path := asset_path(slot_id)
	return not path.is_empty() and ResourceLoader.exists(path)

static func load_scene(slot_id: StringName) -> PackedScene:
	if not has_asset(slot_id):
		return null
	var resource := load(asset_path(slot_id))
	return resource as PackedScene if resource is PackedScene else null

static func instantiate(slot_id: StringName) -> Node3D:
	var scene := load_scene(slot_id)
	if scene == null:
		return null
	return scene.instantiate() as Node3D

static func budget_for(slot_id: StringName) -> Dictionary:
	return slot(slot_id).get("budget", {}) as Dictionary

static func runtime_policy(slot_id: StringName) -> Dictionary:
	return slot(slot_id).get("runtime", {}) as Dictionary

static func configure_runtime_geometry(root: Node, slot_id: StringName) -> int:
	var policy := runtime_policy(slot_id)
	var cast_shadow := bool(policy.get("cast_shadow", false))
	var mesh_count := 0
	for child: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		mesh_instance.cast_shadow = (
			GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			if cast_shadow
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		)
		mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		mesh_count += 1
	return mesh_count

static func geometry_report(slot_id: StringName) -> Dictionary:
	var report := {
		"slot": String(slot_id),
		"exists": has_asset(slot_id),
		"meshes": 0,
		"surfaces": 0,
		"vertices": 0,
		"triangles": 0,
		"material_slots": 0,
		"budget": budget_for(slot_id),
		"prototype_exempt": bool(slot(slot_id).get("prototype_exempt", false))
	}
	var instance := instantiate(slot_id)
	if instance == null:
		return report
	for child: Node in instance.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		report.meshes += 1
		for surface_index in mesh_instance.mesh.get_surface_count():
			report.surfaces += 1
			report.material_slots += 1
			var arrays := mesh_instance.mesh.surface_get_arrays(surface_index)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			report.vertices += vertices.size()
			report.triangles += indices.size() / 3 if not indices.is_empty() else vertices.size() / 3
	instance.free()
	var budget: Dictionary = report.budget
	report.over_triangle_target = report.triangles > int(budget.get("target_triangles", 0))
	report.over_triangle_hard_max = report.triangles > int(budget.get("hard_max_triangles", 0))
	report.over_material_max = report.material_slots > int(budget.get("max_materials", 0))
	return report

static func audit_slots() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var assets: Dictionary = manifest().get("assets", {})
	for key: String in assets:
		var entry: Dictionary = assets[key]
		var path := String(entry.get("path", ""))
		results.append({
			"slot": key,
			"required": bool(entry.get("required", false)),
			"path": path,
			"exists": not path.is_empty() and ResourceLoader.exists(path),
			"prototype_exempt": bool(entry.get("prototype_exempt", false))
		})
	return results
