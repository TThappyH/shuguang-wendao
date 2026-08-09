class_name FlyingSword
extends Node3D

signal shot_fired
signal hit_registered(enemy: Node, hit_count: int)
signal multi_hit_completed(hit_count: int)
signal impact(world_position: Vector3, hit_count: int, damage: float)
signal state_changed(index: int, state_name: StringName)

enum SwordState { FORMATION, ACQUIRE, ANTICIPATE, LAUNCH, TRAVEL, IMPACT, RETURN, REFORM }

const MODEL_ASSET_SLOT: StringName = &"qingyao_flying_sword"

var state := SwordState.FORMATION
var formation_index := 0
var player: Node3D
var target: Node3D
var speed := 18.0
var damage := 34.0
var attack_range := 15.5
var penetration_distance := 8.0
var max_hits := 2
var reform_cooldown := 0.72
var cooldown := 0.0
var state_time := 0.0
var travel_direction := Vector3.ZERO
var first_hit_position := Vector3.ZERO
var hit_targets: Array[Node] = []
var _trail_points: Array[Vector3] = []
var _blade_root: Node3D
var _trail_mesh: ImmediateMesh
var _trail_instance: MeshInstance3D
var _trail_material: StandardMaterial3D

func _ready() -> void:
	_build_sword_visual()
	_build_trail()

func configure(owner_player: Node3D, index: int) -> void:
	player = owner_player
	formation_index = index
	cooldown = float(index) * 0.26

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	state_time += delta
	cooldown = maxf(0.0, cooldown - delta)
	match state:
		SwordState.FORMATION:
			_update_formation(delta)
			if cooldown <= 0.0:
				_set_state(SwordState.ACQUIRE)
		SwordState.ACQUIRE:
			target = _nearest_target()
			_set_state(SwordState.ANTICIPATE if is_instance_valid(target) else SwordState.FORMATION)
		SwordState.ANTICIPATE:
			_update_formation(delta, 0.45)
			if not is_instance_valid(target):
				_set_state(SwordState.RETURN)
			elif state_time >= 0.12:
				_set_state(SwordState.LAUNCH)
		SwordState.LAUNCH:
			travel_direction = (target.global_position + Vector3.UP * 0.8 - global_position).normalized()
			hit_targets.clear()
			_trail_points.clear()
			shot_fired.emit()
			_set_state(SwordState.TRAVEL)
		SwordState.TRAVEL:
			_update_travel(delta)
		SwordState.IMPACT:
			if state_time >= 0.045:
				_set_state(SwordState.TRAVEL if hit_targets.size() < max_hits else SwordState.RETURN)
		SwordState.RETURN:
			_update_return(delta)
		SwordState.REFORM:
			_update_formation(delta)
			if state_time >= 0.14:
				cooldown = reform_cooldown + formation_index * 0.08
				_set_state(SwordState.FORMATION)

func _set_state(next_state: SwordState) -> void:
	if state == next_state:
		return
	if next_state == SwordState.RETURN and hit_targets.size() > 1:
		multi_hit_completed.emit(hit_targets.size())
	state = next_state
	state_time = 0.0
	state_changed.emit(formation_index, StringName(SwordState.keys()[state]))

func _formation_position() -> Vector3:
	var offsets := [Vector3(-1.05, 1.45, 0.65), Vector3(0.0, 1.9, 0.95), Vector3(1.05, 1.45, 0.65)]
	return player.global_position + offsets[formation_index]

func _update_formation(delta: float, expansion := 1.0) -> void:
	var destination := _formation_position()
	destination.x = player.global_position.x + (destination.x - player.global_position.x) * expansion
	global_position = global_position.lerp(destination, 1.0 - exp(-delta * 15.0))
	rotation.y = player.rotation.y
	rotation.z = sin(Time.get_ticks_msec() * 0.004 + formation_index) * 0.08
	if not _trail_points.is_empty():
		_trail_points.clear()
		_redraw_trail()

func _update_travel(delta: float) -> void:
	var previous_position := global_position
	global_position += travel_direction * speed * delta
	look_at(global_position + travel_direction, Vector3.UP)
	rotation.x += PI * 0.5
	_append_trail_point(global_position)
	_check_enemy_hits(previous_position, global_position)
	if not hit_targets.is_empty() and global_position.distance_to(first_hit_position) >= penetration_distance:
		_set_state(SwordState.RETURN)
	elif global_position.distance_to(player.global_position) > attack_range + penetration_distance:
		_set_state(SwordState.RETURN)

func _check_enemy_hits(segment_start: Vector3, segment_end: Vector3) -> void:
	if hit_targets.size() >= max_hits:
		_set_state(SwordState.RETURN)
		return
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy in hit_targets or not enemy.has_method("take_damage"):
			continue
		var enemy_center := (enemy as Node3D).global_position + Vector3.UP * 0.7
		if segment_distance_squared(enemy_center, segment_start, segment_end) > 0.82 * 0.82:
			continue
		hit_targets.append(enemy)
		if hit_targets.size() == 1:
			first_hit_position = global_position
		enemy.take_damage(damage, travel_direction)
		hit_registered.emit(enemy, hit_targets.size())
		impact.emit(enemy_center, hit_targets.size(), damage)
		_set_state(SwordState.IMPACT)
		return

static func segment_distance_squared(point: Vector3, segment_start: Vector3, segment_end: Vector3) -> float:
	var segment := segment_end - segment_start
	var length_squared := segment.length_squared()
	if length_squared <= 0.000001:
		return point.distance_squared_to(segment_start)
	var ratio := clampf((point - segment_start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_squared_to(segment_start + segment * ratio)

func _update_return(delta: float) -> void:
	var destination := _formation_position()
	var direction := (destination - global_position).normalized()
	global_position += direction * speed * 1.2 * delta
	look_at(destination, Vector3.UP)
	_append_trail_point(global_position)
	if global_position.distance_to(destination) < 0.5:
		_set_state(SwordState.REFORM)

func _nearest_target() -> Node3D:
	var result: Node3D
	var best_distance := attack_range
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy is Node3D:
			continue
		var distance := player.global_position.distance_to((enemy as Node3D).global_position)
		if distance < best_distance:
			best_distance = distance
			result = enemy as Node3D
	return result

func reset_runtime() -> void:
	target = null
	hit_targets.clear()
	_trail_points.clear()
	travel_direction = Vector3.ZERO
	first_hit_position = Vector3.ZERO
	cooldown = float(formation_index) * 0.26
	state = SwordState.FORMATION
	state_time = 0.0
	if is_instance_valid(player):
		global_position = _formation_position()

func _build_sword_visual() -> void:
	_blade_root = Node3D.new()
	_blade_root.name = "QingyaoFlyingSwordVisual"
	add_child(_blade_root)
	var rodin_sword := RodinAssetRegistry.instantiate(MODEL_ASSET_SLOT)
	if rodin_sword != null:
		rodin_sword.name = "QingyaoFlyingSwordV1"
		_blade_root.add_child(rodin_sword)
		return
	_build_fallback_sword_visual()

func _build_trail() -> void:
	_trail_mesh = ImmediateMesh.new()
	_trail_instance = MeshInstance3D.new()
	_trail_instance.name = "SwordTrail"
	_trail_instance.mesh = _trail_mesh
	_trail_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_trail_instance)
	_trail_material = StandardMaterial3D.new()
	_trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_material.vertex_color_use_as_albedo = true
	_trail_material.albedo_color = Color(0.45, 0.98, 0.9, 0.8)
	_trail_material.emission_enabled = true
	_trail_material.emission = Color(0.22, 0.84, 0.76)
	_trail_material.emission_energy_multiplier = 1.35
	_trail_material.cull_mode = BaseMaterial3D.CULL_DISABLED

func _append_trail_point(world_point: Vector3) -> void:
	if not _trail_points.is_empty() and _trail_points.back().distance_squared_to(world_point) < 0.06:
		return
	_trail_points.append(world_point)
	while _trail_points.size() > 14:
		_trail_points.pop_front()
	_redraw_trail()

func _redraw_trail() -> void:
	if _trail_mesh == null:
		return
	_trail_mesh.clear_surfaces()
	if _trail_points.size() < 2:
		return
	_trail_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _trail_material)
	for index in _trail_points.size():
		var point := _trail_points[index]
		var direction := Vector3.ZERO
		if index == 0:
			direction = _trail_points[1] - point
		else:
			direction = point - _trail_points[index - 1]
		direction.y = 0.0
		var side := Vector3.UP.cross(direction.normalized()) if direction.length_squared() > 0.0001 else Vector3.RIGHT
		var life := float(index + 1) / float(_trail_points.size())
		var width := lerpf(0.025, 0.13, life)
		var color := Color(0.32, 0.95, 0.86, life * life * 0.78)
		_trail_mesh.surface_set_color(color)
		_trail_mesh.surface_add_vertex(to_local(point + side * width))
		_trail_mesh.surface_set_color(color)
		_trail_mesh.surface_add_vertex(to_local(point - side * width))
	_trail_mesh.surface_end()

func _build_fallback_sword_visual() -> void:
	var blade := MeshInstance3D.new()
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.105, 0.055, 1.22)
	blade.mesh = blade_mesh
	blade.material_override = ArtPalette.material(Color("d8eeea"), 0.22, 0.72, Color("62dfd1"), 0.42)
	blade.position.z = -0.3
	_blade_root.add_child(blade)
	var point := MeshInstance3D.new()
	var point_mesh := PrismMesh.new()
	point_mesh.size = Vector3(0.22, 0.08, 0.42)
	point.mesh = point_mesh
	point.material_override = blade.material_override
	point.position.z = -1.11
	point.rotation.x = PI * 0.5
	_blade_root.add_child(point)
	var guard := MeshInstance3D.new()
	var guard_mesh := BoxMesh.new()
	guard_mesh.size = Vector3(0.52, 0.11, 0.1)
	guard.mesh = guard_mesh
	guard.material_override = ArtPalette.material(ArtPalette.PALE_GOLD, 0.28, 0.56)
	guard.position.z = 0.34
	_blade_root.add_child(guard)
	var grip := MeshInstance3D.new()
	var grip_mesh := CylinderMesh.new()
	grip_mesh.top_radius = 0.07
	grip_mesh.bottom_radius = 0.08
	grip_mesh.height = 0.42
	grip.mesh = grip_mesh
	grip.material_override = ArtPalette.material(ArtPalette.INK_TEAL, 0.8)
	grip.position.z = 0.58
	grip.rotation.x = PI * 0.5
	_blade_root.add_child(grip)
