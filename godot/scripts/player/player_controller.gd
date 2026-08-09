class_name PlayerController
extends CharacterBody3D

signal health_changed(current: float, maximum: float)
signal distance_changed(total_distance: float)
signal damage_taken(amount: float)
signal dash_started(direction: Vector3)
signal dash_ready_changed(ready: bool)
signal died

@export var level_path: NodePath
@export var move_speed := 5.4
@export var acceleration := 22.0
@export var deceleration := 30.0
@export var dash_speed := 13.5
@export var dash_duration := 0.18
@export var dash_cooldown := 1.05

var max_hp := 120.0
var hp := 120.0
var total_distance := 0.0
var contact_immunity := 0.0
var _dash_time := 0.0
var _dash_cooldown_left := 0.0
var _dash_direction := Vector3.ZERO
var _level: Node
var _visual_root: Node3D
var _presentation: PlayerPresentation
var _visual: QingyaoVisual
var _base_move_speed := 5.4
var _base_dash_cooldown := 1.05
var _base_max_hp := 120.0
var _dash_was_ready := true

func _ready() -> void:
	add_to_group("player")
	_level = get_node_or_null(level_path) if not level_path.is_empty() else null
	if _level == null:
		_level = get_parent().get_parent().get_node_or_null("World")
	if _level == null and get_tree().current_scene != null:
		_level = get_tree().current_scene.get_node_or_null("World")
	_visual_root = $VisualRoot
	_setup_collision()
	_presentation = PlayerPresentation.new()
	_presentation.name = "PlayerPresentation"
	_visual_root.add_child(_presentation)
	_visual = QingyaoVisual.new()
	_presentation.add_child(_visual)
	_presentation.configure(_visual)
	health_changed.emit(hp, max_hp)
	_base_move_speed = move_speed
	_base_dash_cooldown = dash_cooldown
	_base_max_hp = max_hp

func _setup_collision() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.39
	capsule.height = 1.72
	$CollisionShape3D.shape = capsule
	$CollisionShape3D.position.y = 0.86

func _physics_process(delta: float) -> void:
	contact_immunity = maxf(0.0, contact_immunity - delta)
	_dash_cooldown_left = maxf(0.0, _dash_cooldown_left - delta)
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_direction := Vector3(input_vector.x, 0.0, input_vector.y)
	if Input.is_action_just_pressed("dash") and _dash_cooldown_left <= 0.0 and not move_direction.is_zero_approx():
		_dash_time = dash_duration
		_dash_cooldown_left = dash_cooldown
		_dash_direction = move_direction.normalized()
		dash_started.emit(_dash_direction)
	var desired := move_direction.normalized() * move_speed
	if _dash_time > 0.0:
		_dash_time -= delta
		var dash_ratio_left := clampf(_dash_time / maxf(dash_duration, 0.001), 0.0, 1.0)
		desired = _dash_direction * dash_speed * lerpf(0.78, 1.0, dash_ratio_left)
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var response := acceleration if not desired.is_zero_approx() else deceleration
	horizontal = horizontal.move_toward(desired, response * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	velocity.y = 0.0
	var before := global_position
	move_and_slide()
	global_position.y = 0.08
	if is_instance_valid(_level) and _level.has_method("can_stand") and not _level.can_stand(global_position, 0.42):
		global_position = before
		velocity = Vector3.ZERO
	var travelled := before.distance_to(global_position)
	if travelled > 0.0001:
		total_distance += travelled
		distance_changed.emit(total_distance)
		_face_motion(Vector3(velocity.x, 0.0, velocity.z), delta)
	_presentation.set_motion(Vector3(velocity.x, 0.0, velocity.z), move_speed, is_dashing(), delta)
	var dash_ready := _dash_cooldown_left <= 0.0
	if dash_ready != _dash_was_ready:
		_dash_was_ready = dash_ready
		dash_ready_changed.emit(dash_ready)

func _face_motion(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.04:
		return
	var target_angle := atan2(direction.x, direction.z)
	_visual_root.rotation.y = lerp_angle(_visual_root.rotation.y, target_angle, 1.0 - exp(-delta * 12.0))

func take_contact_damage(amount: float) -> bool:
	if contact_immunity > 0.0 or _dash_time > 0.0 or hp <= 0.0:
		return false
	contact_immunity = 0.62
	hp = maxf(0.0, hp - amount)
	_presentation.notify_damage()
	health_changed.emit(hp, max_hp)
	damage_taken.emit(amount)
	GameEvents.player_damaged.emit(amount, hp)
	if hp <= 0.0:
		_presentation.notify_death()
		died.emit()
	return true

func reset_runtime() -> void:
	move_speed = _base_move_speed
	dash_cooldown = _base_dash_cooldown
	max_hp = _base_max_hp
	hp = max_hp
	total_distance = 0.0
	contact_immunity = 0.0
	global_position = Vector3(0, 0.08, 2)
	velocity = Vector3.ZERO
	_dash_time = 0.0
	_dash_cooldown_left = 0.0
	_dash_was_ready = true
	_visual_root.rotation = Vector3.ZERO
	_presentation.reset_runtime()
	health_changed.emit(hp, max_hp)
	distance_changed.emit(total_distance)
	dash_ready_changed.emit(true)

func apply_upgrade(stat: StringName, amount: float) -> void:
	match stat:
		&"max_hp":
			max_hp += amount
			hp = minf(max_hp, hp + amount)
			health_changed.emit(hp, max_hp)
		&"move_speed_multiplier":
			move_speed *= 1.0 + amount
		&"dash_cooldown_reduction":
			dash_cooldown = maxf(_base_dash_cooldown * 0.52, dash_cooldown * (1.0 - amount))
		_:
			push_warning("Unknown player upgrade stat: %s" % stat)

func is_dashing() -> bool:
	return _dash_time > 0.0

func dash_ratio() -> float:
	return clampf(1.0 - _dash_cooldown_left / maxf(dash_cooldown, 0.001), 0.0, 1.0)

func presentation_snapshot() -> Dictionary:
	return _presentation.snapshot() if is_instance_valid(_presentation) else {}
