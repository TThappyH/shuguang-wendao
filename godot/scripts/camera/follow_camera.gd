class_name FollowCamera
extends Node3D

@export var target_path: NodePath
@export var follow_height := 28.0
@export var follow_distance := 10.5
@export var look_ahead := 2.2
@export var smooth_speed := 7.5
@export var shake_decay := 1.8
@export var max_horizontal_shake := 0.22
@export var max_vertical_shake := 0.14
@export var max_roll := 0.014

var _target: Node3D
var _camera: Camera3D
var _last_target_position := Vector3.ZERO
var _velocity_hint := Vector3.ZERO
var _trauma := 0.0
var _shake_clock := 0.0

func _ready() -> void:
	_target = get_node(target_path)
	_camera = $Camera3D
	_last_target_position = _target.global_position
	_snap_to_target()

func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		return
	var motion := (_target.global_position - _last_target_position) / maxf(delta, 0.001)
	_last_target_position = _target.global_position
	_velocity_hint = _velocity_hint.lerp(motion, 1.0 - exp(-delta * 4.0))
	var lead := Vector3(_velocity_hint.x, 0.0, _velocity_hint.z).limit_length(1.0) * look_ahead
	var desired := _target.global_position + Vector3(0.0, follow_height, follow_distance) + lead
	global_position = global_position.lerp(desired, 1.0 - exp(-delta * smooth_speed))
	_camera.look_at(_target.global_position + lead * 0.45 + Vector3(0.0, 0.5, -1.4), Vector3.UP)
	_update_shake(delta)

func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)

func reset_runtime() -> void:
	_trauma = 0.0
	_shake_clock = 0.0
	_camera.h_offset = 0.0
	_camera.v_offset = 0.0
	_camera.rotation.z = 0.0
	_snap_to_target()

func _update_shake(delta: float) -> void:
	_shake_clock += delta
	_trauma = maxf(0.0, _trauma - shake_decay * delta)
	var strength := _trauma * _trauma
	_camera.h_offset = sin(_shake_clock * 47.0) * max_horizontal_shake * strength
	_camera.v_offset = sin(_shake_clock * 61.0 + 1.7) * max_vertical_shake * strength
	_camera.rotation.z = sin(_shake_clock * 39.0 + 0.4) * max_roll * strength

func _snap_to_target() -> void:
	global_position = _target.global_position + Vector3(0.0, follow_height, follow_distance)
	_camera.look_at(_target.global_position + Vector3(0.0, 0.5, -1.4), Vector3.UP)
