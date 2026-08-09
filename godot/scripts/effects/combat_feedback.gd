class_name CombatFeedback
extends Node3D

const POOL_SIZE := 24

var _camera: FollowCamera
var _pool: Array[MeshInstance3D] = []
var _cursor := 0
var _active_tweens: Dictionary = {}

func _ready() -> void:
	_build_pool()

func configure(camera: FollowCamera) -> void:
	_camera = camera

func play_sword_impact(world_position: Vector3, hit_count: int, _damage: float) -> void:
	var effect := _acquire()
	effect.global_position = world_position + Vector3.UP * 0.7
	effect.scale = Vector3.ONE * (0.18 + float(hit_count) * 0.07)
	effect.visible = true
	var tween := create_tween()
	_active_tweens[effect] = tween
	tween.set_parallel(true)
	tween.tween_property(effect, "scale", Vector3.ONE * (0.82 + float(hit_count) * 0.18), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(effect, "rotation:y", effect.rotation.y + PI, 0.16)
	tween.finished.connect(func() -> void:
		effect.visible = false
		_active_tweens.erase(effect)
	)
	if is_instance_valid(_camera):
		_camera.add_trauma(0.11 + float(hit_count) * 0.08)

func play_player_damage(world_position: Vector3, amount: float) -> void:
	var effect := _acquire()
	effect.global_position = world_position + Vector3.UP
	effect.scale = Vector3.ONE * 0.55
	effect.visible = true
	var tween := create_tween()
	_active_tweens[effect] = tween
	tween.tween_property(effect, "scale", Vector3.ONE * 1.15, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func() -> void:
		effect.visible = false
		_active_tweens.erase(effect)
	)
	if is_instance_valid(_camera):
		_camera.add_trauma(clampf(0.2 + amount * 0.01, 0.2, 0.46))

func reset_runtime() -> void:
	for tween: Tween in _active_tweens.values():
		if tween != null and tween.is_valid():
			tween.kill()
	_active_tweens.clear()
	for effect in _pool:
		effect.visible = false

func _build_pool() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.28
	mesh.height = 0.14
	mesh.radial_segments = 12
	mesh.rings = 4
	var material := ArtPalette.material(Color("bfece3"), 0.28, 0.0, Color("5ff4df"), 2.4)
	for index in POOL_SIZE:
		var effect := MeshInstance3D.new()
		effect.name = "ImpactPulse%02d" % index
		effect.mesh = mesh
		effect.material_override = material
		effect.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		effect.visible = false
		add_child(effect)
		_pool.append(effect)

func _acquire() -> MeshInstance3D:
	var effect := _pool[_cursor]
	_cursor = (_cursor + 1) % _pool.size()
	var old_tween: Tween = _active_tweens.get(effect)
	if old_tween != null and old_tween.is_valid():
		old_tween.kill()
	_active_tweens.erase(effect)
	effect.visible = false
	effect.rotation = Vector3.ZERO
	return effect
