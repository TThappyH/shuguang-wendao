class_name FlyingSword
extends Node3D

signal shot_fired
signal hit_registered(enemy: Node, hit_count: int)
signal multi_hit_completed(hit_count: int)
signal impact(world_position: Vector3, hit_count: int, damage: float)

enum SwordState { FORMATION, ACQUIRE, ANTICIPATE, LAUNCH, TRAVEL, IMPACT, RETURN, REFORM }

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

func _ready() -> void:
	_build_sword_visual()

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

func _formation_position() -> Vector3:
	var offsets := [Vector3(-1.05, 1.45, 0.65), Vector3(0.0, 1.9, 0.95), Vector3(1.05, 1.45, 0.65)]
	return player.global_position + offsets[formation_index]

func _update_formation(delta: float, expansion := 1.0) -> void:
	var destination := _formation_position()
	destination.x = player.global_position.x + (destination.x - player.global_position.x) * expansion
	global_position = global_position.lerp(destination, 1.0 - exp(-delta * 15.0))
	rotation.y = player.rotation.y
	rotation.z = sin(Time.get_ticks_msec() * 0.004 + formation_index) * 0.08

func _update_travel(delta: float) -> void:
	var previous_position := global_position
	global_position += travel_direction * speed * delta
	look_at(global_position + travel_direction, Vector3.UP)
	rotation.x += PI * 0.5
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
	add_child(_blade_root)
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
