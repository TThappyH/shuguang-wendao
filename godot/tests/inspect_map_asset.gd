extends SceneTree

const MAP_PATH := "res://assets/maps/qingyun_island/qingyun_island_v1.glb"

func _init() -> void:
	var packed := load(MAP_PATH) as PackedScene
	if packed == null:
		push_error("MAP_ASSET_LOAD_FAILED")
		quit(1)
		return
	var root_node := packed.instantiate()
	var mesh_count := 0
	var vertices := 0
	var triangles := 0
	var material_count := 0
	for child: Node in root_node.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		mesh_count += 1
		for surface_index in mesh_instance.mesh.get_surface_count():
			var arrays := mesh_instance.mesh.surface_get_arrays(surface_index)
			var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			vertices += positions.size()
			triangles += indices.size() / 3 if not indices.is_empty() else positions.size() / 3
			if mesh_instance.mesh.surface_get_material(surface_index) != null:
				material_count += 1
	print("MAP_ASSET_OK meshes=%d vertices=%d triangles=%d materials=%d" % [mesh_count, vertices, triangles, material_count])
	root_node.free()
	quit(0)
