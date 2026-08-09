class_name PlayerPresentation
extends Node3D

signal state_changed(state_name: StringName)

enum MotionState { IDLE, MOVE, DASH, HURT, DEAD }

const ANIMATION_HINTS := {
	MotionState.IDLE: [&"idle", &"stand"],
	MotionState.MOVE: [&"run", &"walk", &"move"],
	MotionState.DASH: [&"dash", &"roll", &"dodge"],
	MotionState.HURT: [&"hurt", &"hit", &"damage"],
	MotionState.DEAD: [&"death", &"dead", &"die"]
}

@export var turn_lean := 0.055
@export var stride_bob := 0.035
@export var dash_pitch := 0.16
@export var response_speed := 13.0

var state := MotionState.IDLE
var _visual: QingyaoVisual
var _animation_player: AnimationPlayer
var _animation_names: Dictionary = {}
var _phase := 0.0
var _speed_ratio := 0.0
var _turn_amount := 0.0
var _hurt_left := 0.0
var _is_dashing := false
var _is_dead := false
var _last_heading := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func configure(owner_visual: QingyaoVisual) -> void:
	_visual = owner_visual
	_discover_animation_backend()
	_apply_state(MotionState.IDLE)

func set_motion(horizontal_velocity: Vector3, max_speed: float, is_dashing: bool, delta: float) -> void:
	var speed := Vector2(horizontal_velocity.x, horizontal_velocity.z).length()
	_speed_ratio = clampf(speed / maxf(max_speed, 0.001), 0.0, 1.35)
	_is_dashing = is_dashing
	if speed > 0.08:
		var heading := atan2(horizontal_velocity.x, horizontal_velocity.z)
		_turn_amount = clampf(angle_difference(_last_heading, heading) / maxf(delta, 0.001) * 0.035, -1.0, 1.0)
		_last_heading = heading
	else:
		_turn_amount = move_toward(_turn_amount, 0.0, delta * 5.0)
	_resolve_state()

func notify_damage() -> void:
	if _is_dead:
		return
	_hurt_left = 0.22
	_apply_state(MotionState.HURT)

func notify_death() -> void:
	_is_dead = true
	_apply_state(MotionState.DEAD)

func reset_runtime() -> void:
	_is_dead = false
	_is_dashing = false
	_hurt_left = 0.0
	_speed_ratio = 0.0
	_turn_amount = 0.0
	_phase = 0.0
	position = Vector3.ZERO
	rotation = Vector3.ZERO
	scale = Vector3.ONE
	_apply_state(MotionState.IDLE)

func snapshot() -> Dictionary:
	return {
		"state": MotionState.keys()[state],
		"skeletal_animation_available": is_instance_valid(_animation_player),
		"mapped_animation_count": _animation_names.size(),
		"procedural_fallback_active": not is_instance_valid(_animation_player)
	}

func _process(delta: float) -> void:
	_hurt_left = maxf(0.0, _hurt_left - delta)
	_phase += delta * lerpf(2.2, 9.4, clampf(_speed_ratio, 0.0, 1.0))
	_resolve_state()
	_update_procedural_pose(delta)

func _resolve_state() -> void:
	if _is_dead:
		_apply_state(MotionState.DEAD)
	elif _hurt_left > 0.0:
		_apply_state(MotionState.HURT)
	elif _is_dashing:
		_apply_state(MotionState.DASH)
	elif _speed_ratio > 0.08:
		_apply_state(MotionState.MOVE)
	else:
		_apply_state(MotionState.IDLE)

func _apply_state(next_state: MotionState) -> void:
	if state == next_state and (not is_instance_valid(_animation_player) or _animation_player.is_playing()):
		return
	state = next_state
	state_changed.emit(StringName(MotionState.keys()[state]))
	if not is_instance_valid(_animation_player):
		return
	var animation_name: StringName = _animation_names.get(state, &"")
	if animation_name != &"" and _animation_player.current_animation != animation_name:
		_animation_player.play(animation_name, 0.12)

func _update_procedural_pose(delta: float) -> void:
	# This fallback keeps an unrigged model readable today. When a rig arrives, the
	# AnimationPlayer owns limb motion while this node continues to provide restrained
	# whole-body anticipation, recoil, and locomotion weight.
	var target_position := Vector3.ZERO
	var target_rotation := Vector3.ZERO
	var target_scale := Vector3.ONE
	match state:
		MotionState.IDLE:
			target_position.y = sin(_phase) * 0.008
			target_rotation.z = sin(_phase * 0.53) * 0.006
			target_scale.y = 1.0 + sin(_phase) * 0.003
		MotionState.MOVE:
			var stride := sin(_phase)
			target_position.y = absf(stride) * stride_bob
			target_rotation.x = -0.035 * clampf(_speed_ratio, 0.0, 1.0)
			target_rotation.z = stride * 0.025 - _turn_amount * turn_lean
			target_scale = Vector3(1.0 - absf(stride) * 0.006, 1.0 + absf(stride) * 0.01, 1.0)
		MotionState.DASH:
			target_position.y = 0.035
			target_rotation.x = -dash_pitch
			target_rotation.z = -_turn_amount * turn_lean * 0.6
			target_scale = Vector3(0.97, 0.96, 1.07)
		MotionState.HURT:
			var recoil := clampf(_hurt_left / 0.22, 0.0, 1.0)
			target_position.y = 0.025 * recoil
			target_rotation.x = 0.13 * recoil
			target_rotation.z = sin(recoil * PI) * 0.08
			target_scale = Vector3(1.035, 0.96, 1.035)
		MotionState.DEAD:
			target_position.y = -0.34
			target_rotation = Vector3(0.08, 0.0, 1.32)
			target_scale = Vector3(1.04, 0.96, 1.0)
	var weight := 1.0 - exp(-delta * response_speed)
	position = position.lerp(target_position, weight)
	rotation.x = lerp_angle(rotation.x, target_rotation.x, weight)
	rotation.z = lerp_angle(rotation.z, target_rotation.z, weight)
	scale = scale.lerp(target_scale, weight)

func _discover_animation_backend() -> void:
	_animation_player = null
	_animation_names.clear()
	if not is_instance_valid(_visual):
		return
	for node: Node in _visual.find_children("*", "AnimationPlayer", true, false):
		_animation_player = node as AnimationPlayer
		break
	if not is_instance_valid(_animation_player):
		return
	var available := _animation_player.get_animation_list()
	for state_id: MotionState in ANIMATION_HINTS:
		for candidate: StringName in available:
			var lower := String(candidate).to_lower()
			for hint: StringName in ANIMATION_HINTS[state_id]:
				if lower.contains(String(hint)):
					_animation_names[state_id] = candidate
					break
			if _animation_names.has(state_id):
				break
