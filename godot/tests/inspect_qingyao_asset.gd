extends SceneTree

func _init() -> void:
	var packed := load("res://assets/characters/qingyao/qingyao_v1.glb") as PackedScene
	if packed == null:
		push_error("QINGYAO_ASSET_LOAD_FAILED")
		quit(1)
		return
	var root_node := packed.instantiate()
	var mesh_count := 0
	var vertices := 0
	var triangles := 0
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
	print("QINGYAO_ASSET_OK meshes=%d vertices=%d triangles=%d" % [mesh_count, vertices, triangles])
	root_node.free()
	quit(0)
