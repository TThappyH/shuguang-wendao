class_name LevelBuilder
extends Node3D

const WATER_SHADER := preload("res://shaders/spirit_water.gdshader")
const SIGIL_SHADER := preload("res://shaders/spirit_sigil.gdshader")
const MAP_ASSET_SLOT: StringName = &"qingyun_island"
const EXTERNAL_MAP_FALLBACK_PATH := "res://assets/maps/qingyun_island/qingyun_island_v1.glb"
const EXTERNAL_MAP_Y_OFFSET := -44.35

var _world_root: Node3D
var _blockers: Array[StaticBody3D] = []
var _region_markers: Dictionary = {}
var external_map_loaded := false
var loaded_asset_path := ""

func _ready() -> void:
	_build_environment()
	_world_root = Node3D.new()
	_world_root.name = "QingyunIslandWorld"
	add_child(_world_root)
	if _build_external_map():
		_build_gameplay_collision_graph()
	else:
		_world_root.name = "FiveRealmArtFallback"
		_build_backdrop()
		_build_floor_graph()
		_build_central_courtyard()
		_build_bamboo_realm()
		_build_marsh_realm()
		_build_sword_realm()
		_build_ember_realm()
		_build_gate_arches()

func can_stand(position: Vector3, radius := WorldConfig.PLAYER_RADIUS) -> bool:
	return WorldConfig.is_walkable(position, radius)

func _build_gameplay_collision_graph() -> void:
	# The Rodin map is presentation only. Gameplay remains deterministic and uses the
	# same authored footprints as the whitebox so art replacement cannot silently
	# remove cover, gates, or traversal constraints.
	for id: String in WorldConfig.REGIONS:
		var region: Dictionary = WorldConfig.REGIONS[id]
		_add_floor_collision(region.center, region.size, id)
	for link: Dictionary in WorldConfig.LINKS:
		_add_floor_collision(link.center, link.size, String(link.id))
	for blocker: Dictionary in WorldConfig.BLOCKERS:
		_add_blocker_collision(blocker)

func _add_floor_collision(center: Vector2, size: Vector2, id: String) -> void:
	var body := StaticBody3D.new()
	body.name = "GameplayFloor_%s" % id
	body.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 0.18, size.y)
	shape.shape = box
	shape.position = Vector3(center.x, -0.12, center.y)
	body.add_child(shape)
	add_child(body)

func _add_blocker_collision(blocker: Dictionary) -> void:
	var body := StaticBody3D.new()
	body.name = "GameplayBlocker_%s" % String(blocker.id)
	body.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(blocker.s.x, blocker.h, blocker.s.y)
	shape.shape = box
	shape.position = Vector3(blocker.p.x, blocker.h * 0.5, blocker.p.y)
	body.add_child(shape)
	add_child(body)
	_blockers.append(body)

func _build_external_map() -> bool:
	loaded_asset_path = RodinAssetRegistry.asset_path(MAP_ASSET_SLOT)
	if loaded_asset_path.is_empty():
		loaded_asset_path = EXTERNAL_MAP_FALLBACK_PATH
	var resource := load(loaded_asset_path)
	if not resource is PackedScene:
		push_error("External map failed to import: %s" % loaded_asset_path)
		return false
	var map_root := (resource as PackedScene).instantiate() as Node3D
	if map_root == null:
		push_error("External map root is not Node3D")
		return false
	map_root.name = "QingyunIslandExternalMap"
	map_root.position.y = EXTERNAL_MAP_Y_OFFSET
	for child: Node in map_root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		mesh_instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	_world_root.add_child(map_root)
	external_map_loaded = true
	return true

func snapshot() -> Dictionary:
	return {
		"external_map_loaded": external_map_loaded,
		"asset_slot": String(MAP_ASSET_SLOT),
		"asset_path": loaded_asset_path,
		"fallback_blockers": _blockers.size(),
		"gameplay_collision_proxies": _blockers.size(),
		"navigation_profile": "FIVE_REGION_GRAPH"
	}

func _build_environment() -> void:
	var environment := Environment.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("517f96")
	sky_material.sky_horizon_color = Color("c0d8ce")
	sky_material.ground_bottom_color = Color("35565d")
	sky_material.ground_horizon_color = Color("9fbeb6")
	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_color = Color("bfded7")
	environment.ambient_light_energy = 0.17
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 0.48
	environment.fog_enabled = true
	environment.fog_light_color = Color("b5cfca")
	environment.fog_light_energy = 0.68
	environment.fog_density = 0.0065
	environment.fog_height = 5.0
	environment.fog_height_density = 0.045
	environment.glow_enabled = true
	environment.glow_intensity = 0.38
	environment.glow_strength = 0.58
	var world := WorldEnvironment.new()
	world.name = "XianxiaAtmosphere"
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "MorningSun"
	sun.rotation_degrees = Vector3(-52.0, -34.0, 0.0)
	sun.light_color = Color("ffe6bf")
	sun.light_energy = 0.58
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.name = "JadeFill"
	fill.rotation_degrees = Vector3(-34.0, 142.0, 0.0)
	fill.light_color = Color("b7e6e1")
	fill.light_energy = 0.14
	add_child(fill)
	var rim := OmniLight3D.new()
	rim.name = "CourtyardRim"
	rim.position = Vector3(0, 5.0, -4.0)
	rim.light_color = ArtPalette.JADE_GLOW
	rim.light_energy = 1.6
	rim.omni_range = 15.0
	add_child(rim)

func _build_backdrop() -> void:
	var ground := MeshInstance3D.new()
	var ground_mesh := BoxMesh.new()
	ground_mesh.size = Vector3(108.0, 0.22, 108.0)
	ground.mesh = ground_mesh
	ground.material_override = ArtPalette.material(Color("4d7776"), 0.98)
	ground.position.y = -0.42
	_world_root.add_child(ground)
	for i in 9:
		var mountain := MeshInstance3D.new()
		var mountain_mesh := PrismMesh.new()
		mountain_mesh.size = Vector3(12.0 + float(i % 3) * 4.0, 8.0 + float(i % 4) * 2.0, 5.0)
		mountain.mesh = mountain_mesh
		mountain.material_override = ArtPalette.material(Color("6e9691"), 1.0)
		mountain.position = Vector3(-48.0 + float(i) * 12.0, 2.7, -29.0 - float(i % 2) * 4.0)
		mountain.rotation.y = float(i) * 0.31
		_world_root.add_child(mountain)

func _build_floor_graph() -> void:
	for id: String in WorldConfig.REGIONS:
		var region: Dictionary = WorldConfig.REGIONS[id]
		_add_floor(region.center, region.size, region.floor, id)
		_add_region_marker(id, region.center, region.accent)
	for link: Dictionary in WorldConfig.LINKS:
		_add_floor(link.center, link.size, Color("a7c1b7"), link.id)
	for blocker: Dictionary in WorldConfig.BLOCKERS:
		_add_blocker(blocker)

func _add_floor(center: Vector2, size: Vector2, color: Color, id: String) -> void:
	var floor := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, 0.18, size.y)
	floor.mesh = mesh
	floor.material_override = ArtPalette.material(color, 0.93)
	floor.position = Vector3(center.x, -0.12, center.y)
	floor.name = "Floor_%s" % id
	_world_root.add_child(floor)
	var body := StaticBody3D.new()
	body.name = "FloorCollision_%s" % id
	body.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 0.18, size.y)
	shape.shape = box
	shape.position = Vector3(center.x, -0.12, center.y)
	body.add_child(shape)
	add_child(body)

func _add_blocker(blocker: Dictionary) -> void:
	var kind: String = blocker.kind
	var material := ArtPalette.material(ArtPalette.WARM_STONE, 0.86)
	match kind:
		"pillar": material = ArtPalette.material(ArtPalette.BAMBOO, 0.9)
		"island": material = ArtPalette.material(Color("789a82"), 0.96)
		"stele": material = ArtPalette.material(ArtPalette.SWORD_STONE, 0.82)
		"canyon": material = ArtPalette.material(ArtPalette.EMBER_ROCK, 0.98)
	var mesh_node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(blocker.s.x, blocker.h, blocker.s.y)
	mesh_node.mesh = mesh
	mesh_node.material_override = material
	mesh_node.position = Vector3(blocker.p.x, blocker.h * 0.5, blocker.p.y)
	mesh_node.name = "ArtBlock_%s" % blocker.id
	_world_root.add_child(mesh_node)
	var body := StaticBody3D.new()
	body.name = "Collision_%s" % blocker.id
	body.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(blocker.s.x, blocker.h, blocker.s.y)
	shape.shape = box_shape
	shape.position = mesh_node.position
	body.add_child(shape)
	add_child(body)
	_blockers.append(body)
	if kind == "stele":
		_add_stele_cap(blocker.p, blocker.h)
	elif kind == "canyon":
		_add_ember_crystals(Vector3(blocker.p.x, blocker.h, blocker.p.y), blocker.s)

func _add_region_marker(id: String, center: Vector2, accent: Color) -> void:
	var marker := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(7.0, 7.0)
	marker.mesh = plane
	var material := ShaderMaterial.new()
	material.shader = SIGIL_SHADER
	material.set_shader_parameter("inner_color", Color(accent.r, accent.g, accent.b, 1.0))
	marker.material_override = material
	marker.position = Vector3(center.x, 0.012, center.y)
	marker.name = "RegionSigil_%s" % id
	_world_root.add_child(marker)
	_region_markers[id] = marker

func _build_central_courtyard() -> void:
	for axis in [-1.0, 1.0]:
		for step in 4:
			var tile := MeshInstance3D.new()
			var tile_mesh := BoxMesh.new()
			tile_mesh.size = Vector3(0.12, 0.025, 19.0)
			tile.mesh = tile_mesh
			tile.material_override = ArtPalette.material(Color("d9decf"), 0.88)
			tile.position = Vector3(axis * (2.6 + step * 2.5), 0.015, 0)
			_world_root.add_child(tile)
	var pavilion := Node3D.new()
	pavilion.name = "JadePavilion"
	_world_root.add_child(pavilion)
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			_add_cylinder(pavilion, Vector3(x * 4.6, 1.55, z * 4.6), 0.26, 3.1, ArtPalette.JADE_WHITE, "Pillar")
	var beam := MeshInstance3D.new()
	var beam_mesh := BoxMesh.new()
	beam_mesh.size = Vector3(10.0, 0.28, 0.34)
	beam.mesh = beam_mesh
	beam.material_override = ArtPalette.material(ArtPalette.INK_TEAL, 0.76)
	beam.position.y = 3.12
	pavilion.add_child(beam)
	var roof := MeshInstance3D.new()
	var roof_mesh := PrismMesh.new()
	roof_mesh.size = Vector3(11.6, 0.6, 7.5)
	roof.mesh = roof_mesh
	roof.material_override = ArtPalette.material(ArtPalette.QING_TEAL, 0.58)
	roof.position.y = 3.55
	roof.rotation.y = PI * 0.25
	pavilion.add_child(roof)
	var roof_ridge := MeshInstance3D.new()
	var ridge_mesh := BoxMesh.new()
	ridge_mesh.size = Vector3(8.0, 0.16, 0.18)
	roof_ridge.mesh = ridge_mesh
	roof_ridge.material_override = ArtPalette.material(ArtPalette.PALE_GOLD, 0.35, 0.4)
	roof_ridge.position = Vector3(0, 3.88, 0)
	pavilion.add_child(roof_ridge)
	_add_lotus_tree(Vector3(0, 0.2, 0), 0.8)

func _build_bamboo_realm() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8301
	for i in 42:
		var x := rng.randf_range(18.0, 39.0)
		var z := rng.randf_range(-11.0, 11.0)
		if absf(z) < 3.0 and x < 25.0:
			continue
		_add_bamboo_cluster(Vector3(x, 0, z), 2 + i % 3, rng.randf_range(2.8, 4.8), rng)
	for z in [-11.0, 11.0]:
		_add_bamboo_rail(Vector3(28, 0, z), 21.0)

func _add_bamboo_cluster(center: Vector3, count: int, height: float, rng: RandomNumberGenerator) -> void:
	for i in count:
		var offset := Vector3(rng.randf_range(-0.65, 0.65), 0, rng.randf_range(-0.65, 0.65))
		_add_cylinder(_world_root, center + offset + Vector3.UP * (height * 0.5), 0.12, height, ArtPalette.BAMBOO, "BambooStalk")
		var crown := MeshInstance3D.new()
		var crown_mesh := SphereMesh.new()
		crown_mesh.radius = 0.62
		crown_mesh.height = 1.3
		crown.mesh = crown_mesh
		crown.material_override = ArtPalette.material(ArtPalette.BAMBOO_LIGHT, 0.92)
		crown.scale = Vector3(1.2, 0.42, 0.7)
		crown.position = center + offset + Vector3(0, height + 0.1, 0)
		_world_root.add_child(crown)

func _add_bamboo_rail(center: Vector3, length: float) -> void:
	var rail := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(length, 0.12, 0.14)
	rail.mesh = mesh
	rail.material_override = ArtPalette.material(ArtPalette.BAMBOO, 0.82)
	rail.position = center + Vector3(0, 1.05, 0)
	_world_root.add_child(rail)

func _build_marsh_realm() -> void:
	var water := MeshInstance3D.new()
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(25.0, 27.0)
	water.mesh = water_mesh
	var water_material := ShaderMaterial.new()
	water_material.shader = WATER_SHADER
	water.material_override = water_material
	water.position = Vector3(-28, 0.02, 0)
	_world_root.add_child(water)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1442
	for i in 20:
		var pad := Vector3(-39.0 + rng.randf_range(0, 21), 0.11, -11.0 + rng.randf_range(0, 22))
		_add_lotus_pad(pad, rng.randf_range(0.45, 0.85))
	for point in [Vector3(-36, 0.22, -7), Vector3(-31, 0.22, 1), Vector3(-23, 0.22, 7)]:
		_add_lantern(point)

func _build_sword_realm() -> void:
	for point in [Vector3(-10,0,-20), Vector3(10,0,-20), Vector3(-10,0,-32), Vector3(10,0,-32), Vector3(0,0,-39)]:
		_add_sword_marker(point)
	for x in [-11.0, 11.0]:
		_add_cylinder(_world_root, Vector3(x, 1.2, -28), 0.12, 2.4, ArtPalette.SWORD_STONE, "BoundaryStone")

func _build_ember_realm() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 8819
	for i in 18:
		var point := Vector3(rng.randf_range(-12.0, 12.0), 0.2, rng.randf_range(18.0, 40.0))
		_add_ember_crystals(point, Vector2.ONE * rng.randf_range(0.6, 1.5))
	for x in [-12.0, 12.0]:
		_add_ember_spire(Vector3(x, 0, 31), rng.randf_range(4.5, 7.5))

func _build_gate_arches() -> void:
	for gate in [Vector3(13,0,0), Vector3(-13,0,0), Vector3(0,0,-13), Vector3(0,0,13)]:
		var arch := Node3D.new()
		arch.position = gate
		_world_root.add_child(arch)
		var axis_x := absf(gate.x) > 0.0
		for side in [-1.0, 1.0]:
			var post_position := Vector3(0, 1.5, side * 3.15) if axis_x else Vector3(side * 3.15, 1.5, 0)
			_add_cylinder(arch, post_position, 0.18, 3.0, ArtPalette.JADE_WHITE, "GatePost")
		var top := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.28, 0.22, 6.6) if axis_x else Vector3(6.6, 0.22, 0.28)
		top.mesh = mesh
		top.material_override = ArtPalette.material(ArtPalette.QING_TEAL, 0.6)
		top.position.y = 3.05
		arch.add_child(top)

func _add_cylinder(parent: Node, position: Vector3, radius: float, height: float, color: Color, node_name: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.92
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	node.mesh = mesh
	node.material_override = ArtPalette.material(color, 0.82)
	node.position = position
	node.name = node_name
	parent.add_child(node)
	return node

func _add_stele_cap(point: Vector2, height: float) -> void:
	var cap := MeshInstance3D.new()
	var mesh := PrismMesh.new()
	mesh.size = Vector3(1.32, 0.3, 1.3)
	cap.mesh = mesh
	cap.material_override = ArtPalette.material(Color("a8c3c1"), 0.64, 0.1, Color("4f9ca5"), 0.18)
	cap.position = Vector3(point.x, height + 0.15, point.y)
	_world_root.add_child(cap)

func _add_ember_crystals(point: Vector3, size: Vector2) -> void:
	for side in [-1.0, 1.0]:
		var crystal := MeshInstance3D.new()
		var mesh := PrismMesh.new()
		mesh.size = Vector3(size.x * 0.32, size.y * 1.5, size.y * 0.36)
		crystal.mesh = mesh
		crystal.material_override = ArtPalette.material(ArtPalette.EMBER_GLOW, 0.32, 0.12, Color("ff6338"), 2.0)
		crystal.position = point + Vector3(side * size.x * 0.32, size.y * 0.8, 0)
		crystal.rotation.z = side * 0.16
		_world_root.add_child(crystal)

func _add_lotus_pad(point: Vector3, radius: float) -> void:
	var pad := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.04
	mesh.height = 0.07
	mesh.radial_segments = 12
	pad.mesh = mesh
	pad.material_override = ArtPalette.material(Color("5f9f79"), 0.72)
	pad.position = point
	_world_root.add_child(pad)
	var flower := MeshInstance3D.new()
	var flower_mesh := SphereMesh.new()
	flower_mesh.radius = radius * 0.34
	flower_mesh.height = radius * 0.36
	flower.mesh = flower_mesh
	flower.material_override = ArtPalette.material(ArtPalette.LOTUS, 0.55, 0.0, Color("d86599"), 0.22)
	flower.position = point + Vector3(0, 0.16, 0)
	_world_root.add_child(flower)

func _add_lotus_tree(point: Vector3, scale_value: float) -> void:
	_add_cylinder(_world_root, point + Vector3(0, 1.0, 0), 0.12 * scale_value, 2.0 * scale_value, ArtPalette.BAMBOO, "LotusStem")
	for angle in [0.0, 2.1, 4.2]:
		var petal := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.42 * scale_value
		mesh.height = 0.18 * scale_value
		petal.mesh = mesh
		petal.material_override = ArtPalette.material(Color("f0d9b9"), 0.62)
		petal.position = point + Vector3(cos(angle) * 0.42, 2.05 * scale_value, sin(angle) * 0.42)
		petal.scale = Vector3(1.3, 0.35, 0.65)
		_world_root.add_child(petal)

func _add_lantern(point: Vector3) -> void:
	_add_cylinder(_world_root, point + Vector3(0, 1.25, 0), 0.055, 2.5, ArtPalette.INK_TEAL, "LanternPole")
	var lantern := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.23
	mesh.height = 0.36
	lantern.mesh = mesh
	lantern.material_override = ArtPalette.material(ArtPalette.PALE_GOLD, 0.3, 0.05, Color("f7bf68"), 2.2)
	lantern.position = point + Vector3(0, 2.2, 0)
	_world_root.add_child(lantern)

func _add_sword_marker(point: Vector3) -> void:
	_add_cylinder(_world_root, point + Vector3(0, 0.9, 0), 0.11, 1.8, ArtPalette.SWORD_STONE, "SwordGrave")
	var blade := MeshInstance3D.new()
	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.09, 1.4, 0.16)
	blade.mesh = mesh
	blade.material_override = ArtPalette.material(Color("a6d8dd"), 0.28, 0.6, Color("5ccad5"), 0.7)
	blade.position = point + Vector3(0, 1.8, 0)
	blade.rotation.z = 0.11
	_world_root.add_child(blade)

func _add_ember_spire(point: Vector3, height: float) -> void:
	var spire := MeshInstance3D.new()
	var mesh := PrismMesh.new()
	mesh.size = Vector3(2.2, height, 2.0)
	spire.mesh = mesh
	spire.material_override = ArtPalette.material(Color("754538"), 0.98)
	spire.position = point + Vector3(0, height * 0.5, 0)
	spire.rotation.y = 0.4
	_world_root.add_child(spire)
	_add_ember_crystals(point + Vector3(0, height * 0.55, 0), Vector2(1.4, 0.7))
