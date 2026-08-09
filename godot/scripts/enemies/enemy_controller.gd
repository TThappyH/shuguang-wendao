class_name EnemyController
extends CharacterBody3D

signal defeated(enemy: EnemyController)
signal contact_damage(amount: float)

enum EnemyState { APPROACH, HIT, DEAD }

var player: Node3D
var level: Node
var archetype: EnemyArchetypeData
var enemy_id := 0
var hp := 64.0
var max_hp := 64.0
var move_speed := 2.35
var acceleration := 5.5
var contact_damage_value := 8.0
var contact_cooldown := 0.68
var contact_range := 1.05
var radius := 0.48
var state := EnemyState.APPROACH
var dead := false
var _contact_timer := 0.0
var _hit_timer := 0.0
var _phase := 0.0
var _knockback_velocity := Vector3.ZERO
var _visual_root: Node3D
var _health_fill: MeshInstance3D

func configure(owner_player: Node3D, owner_level: Node, serial: int, data: EnemyArchetypeData, difficulty_scale := 1.0) -> void:
	player = owner_player
	level = owner_level
	enemy_id = serial
	archetype = data
	if archetype != null:
		max_hp = archetype.max_hp * difficulty_scale
		move_speed = archetype.move_speed
		acceleration = archetype.acceleration
		contact_damage_value = archetype.contact_damage * difficulty_scale
		contact_cooldown = archetype.contact_cooldown
		contact_range = archetype.contact_range
		radius = archetype.radius
	hp = max_hp

func _ready() -> void:
	add_to_group("enemies")
	_setup_collision()
	if not _build_rodin_visual():
		_build_fallback_visual()

func _setup_collision() -> void:
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = maxf(1.1, radius * 2.5)
	collision.shape = shape
	collision.position.y = shape.height * 0.5
	add_child(collision)

func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(player):
		return
	_contact_timer = maxf(0.0, _contact_timer - delta)
	_hit_timer = maxf(0.0, _hit_timer - delta)
	_phase += delta
	if state == EnemyState.HIT and _hit_timer <= 0.0:
		state = EnemyState.APPROACH
	var desired_velocity := Vector3.ZERO
	if state == EnemyState.APPROACH:
		desired_velocity = _approach_velocity()
	_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, delta * 18.0)
	velocity = velocity.lerp(desired_velocity, 1.0 - exp(-delta * acceleration)) + _knockback_velocity
	velocity.y = 0.0
	if velocity.length_squared() > 0.04:
		look_at(global_position + Vector3(velocity.x, 0.0, velocity.z), Vector3.UP)
	move_and_slide()
	global_position.y = 0.08
	if global_position.distance_to(player.global_position) < contact_range and _contact_timer <= 0.0:
		_contact_timer = contact_cooldown
		contact_damage.emit(contact_damage_value)
	_animate_visual()

func _approach_velocity() -> Vector3:
	var desired_target := WorldConfig.navigation_target(global_position, player.global_position)
	var direction := global_position.direction_to(desired_target)
	direction.y = 0.0
	if direction.length_squared() <= 0.001:
		return Vector3.ZERO
	direction = direction.normalized()
	if archetype != null and archetype.behavior == &"flank" and global_position.distance_to(player.global_position) > 3.0:
		var tangent := Vector3(-direction.z, 0.0, direction.x)
		var side := -1.0 if enemy_id % 2 == 0 else 1.0
		direction = (direction + tangent * side * 0.34).normalized()
	return direction * move_speed

func take_damage(amount: float, direction := Vector3.ZERO) -> void:
	if dead:
		return
	hp = maxf(0.0, hp - amount)
	if direction.length_squared() > 0.001:
		_knockback_velocity += direction.normalized() * 1.8
	if hp <= 0.0:
		_die()
	else:
		state = EnemyState.HIT
		_hit_timer = 0.075

func _die() -> void:
	dead = true
	state = EnemyState.DEAD
	velocity = Vector3.ZERO
	remove_from_group("enemies")
	defeated.emit(self)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual_root, "scale", _visual_root.scale * Vector3(1.16, 0.08, 1.16), 0.2).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_visual_root, "position:y", _visual_root.position.y + 0.18, 0.2)
	tween.tween_property(_visual_root, "rotation:y", _visual_root.rotation.y + 0.8, 0.2)
	tween.finished.connect(queue_free)

func state_name() -> String:
	return EnemyState.keys()[state]

func snapshot() -> Dictionary:
	return {
		"id": enemy_id,
		"archetype": String(archetype.id) if archetype != null else "fallback",
		"state": state_name(),
		"hp": hp,
		"speed": move_speed
	}

func _animate_visual() -> void:
	if not is_instance_valid(_visual_root):
		return
	_visual_root.position.y = 0.04 + sin(_phase * 7.0 + enemy_id) * 0.035
	_visual_root.rotation.z = sin(_phase * 4.0 + enemy_id) * 0.035
	if is_instance_valid(_health_fill):
		_health_fill.scale.x = maxf(0.02, hp / maxf(max_hp, 0.01))

func _build_rodin_visual() -> bool:
	if archetype == null or archetype.model_slot == &"":
		return false
	var model := RodinAssetRegistry.instantiate(archetype.model_slot)
	if model == null:
		return false
	_visual_root = Node3D.new()
	_visual_root.name = "RodinEnemyVisual"
	_visual_root.scale = Vector3.ONE * archetype.visual_scale
	add_child(_visual_root)
	_visual_root.add_child(model)
	return true

func _build_fallback_visual() -> void:
	_visual_root = Node3D.new()
	_visual_root.name = "PrototypeEnemyVisual"
	_visual_root.scale = Vector3.ONE * (archetype.visual_scale if archetype != null else 1.0)
	add_child(_visual_root)
	var dark := ArtPalette.material(ArtPalette.ENEMY_CLOTH, 0.9)
	var ember := ArtPalette.material(Color("e48055"), 0.35, 0.05, Color("c4452e"), 1.4)
	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = radius * 0.82
	body_mesh.height = 1.45
	body.mesh = body_mesh
	body.material_override = dark
	body.position.y = 0.75
	_visual_root.add_child(body)
	for side in [-1.0, 1.0]:
		var horn := MeshInstance3D.new()
		var horn_mesh := CylinderMesh.new()
		horn_mesh.top_radius = 0.015
		horn_mesh.bottom_radius = 0.11
		horn_mesh.height = 0.42
		horn.mesh = horn_mesh
		horn.material_override = ember
		horn.position = Vector3(side * 0.18, 1.6, 0.0)
		horn.rotation.z = side * -0.28
		_visual_root.add_child(horn)
	var bar := MeshInstance3D.new()
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(0.82, 0.055, 0.045)
	bar.mesh = bar_mesh
	bar.material_override = ArtPalette.material(Color("243136"), 0.5)
	bar.position = Vector3(0, 1.92, 0)
	_visual_root.add_child(bar)
	_health_fill = MeshInstance3D.new()
	var fill_mesh := BoxMesh.new()
	fill_mesh.size = Vector3(0.78, 0.035, 0.025)
	_health_fill.mesh = fill_mesh
	_health_fill.material_override = ember
	_health_fill.position = Vector3(-0.39, 1.92, -0.03)
	_visual_root.add_child(_health_fill)
