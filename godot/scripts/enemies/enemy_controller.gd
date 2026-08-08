class_name EnemyController
extends CharacterBody3D

signal defeated(enemy: Node)
signal contact_damage(amount: float)

var player: Node3D
var level: Node
var enemy_id := 0
var hp := 64.0
var max_hp := 64.0
var move_speed := 2.25
var contact_damage_value := 9.0
var radius := 0.48
var state := "APPROACH"
var dead := false
var _contact_timer := 0.0
var _visual_root: Node3D
var _health_fill: MeshInstance3D
var _phase := 0.0

func configure(owner_player: Node3D, owner_level: Node, serial: int, difficulty_scale := 1.0) -> void:
	player = owner_player
	level = owner_level
	enemy_id = serial
	hp *= difficulty_scale
	max_hp = hp
	contact_damage_value *= difficulty_scale

func _ready() -> void:
	add_to_group("enemies")
	_setup_collision()
	_build_visual()

func _setup_collision() -> void:
	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null:
		collision = CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		add_child(collision)
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = 1.25
	collision.shape = shape
	collision.position.y = 0.62

func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(player):
		return
	_contact_timer = maxf(0.0, _contact_timer - delta)
	_phase += delta
	var desired_target := WorldConfig.navigation_target(global_position, player.global_position)
	var direction := global_position.direction_to(desired_target)
	direction.y = 0.0
	if direction.length_squared() > 0.001:
		velocity = velocity.lerp(direction.normalized() * move_speed, 1.0 - exp(-delta * 5.5))
		look_at(global_position + Vector3(velocity.x, 0.0, velocity.z), Vector3.UP)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, move_speed * delta * 5.0)
	move_and_slide()
	global_position.y = 0.08
	if global_position.distance_to(player.global_position) < 1.05 and _contact_timer <= 0.0:
		_contact_timer = 0.68
		contact_damage.emit(contact_damage_value)
	_animate(delta)

func _animate(delta: float) -> void:
	if not is_instance_valid(_visual_root):
		return
	_visual_root.position.y = 0.04 + sin(_phase * 7.0 + enemy_id) * 0.035
	_visual_root.rotation.z = sin(_phase * 4.0 + enemy_id) * 0.04
	if is_instance_valid(_health_fill):
		_health_fill.scale.x = maxf(0.02, hp / maxf(max_hp, 0.01))

func take_damage(amount: float, _direction := Vector3.ZERO) -> void:
	if dead:
		return
	hp = maxf(0.0, hp - amount)
	if hp <= 0.0:
		dead = true
		state = "DEAD"
		defeated.emit(self)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector3(1.15, 0.1, 1.15), 0.22)
		tween.tween_property(self, "modulate", Color(1.0, 0.55, 0.38, 0.0), 0.22)
		tween.finished.connect(queue_free)

func _build_visual() -> void:
	_visual_root = Node3D.new()
	_visual_root.name = "SpiritVisual"
	add_child(_visual_root)
	var dark := ArtPalette.material(ArtPalette.ENEMY_CLOTH, 0.9)
	var skin := ArtPalette.material(ArtPalette.ENEMY_SKIN, 0.86)
	var ember := ArtPalette.material(Color("e48055"), 0.35, 0.05, Color("c4452e"), 1.4)
	var bone := ArtPalette.material(Color("d5cfb5"), 0.82)
	var torso := MeshInstance3D.new()
	var torso_mesh := SphereMesh.new()
	torso_mesh.radius = 0.42
	torso_mesh.height = 0.9
	torso.mesh = torso_mesh
	torso.material_override = dark
	torso.position.y = 0.62
	_visual_root.add_child(torso)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.32
	head_mesh.height = 0.55
	head.mesh = head_mesh
	head.material_override = skin
	head.position = Vector3(0, 1.3, 0.04)
	_visual_root.add_child(head)
	for side in [-1.0, 1.0]:
		var horn := MeshInstance3D.new()
		var horn_mesh := CylinderMesh.new()
		horn_mesh.top_radius = 0.015
		horn_mesh.bottom_radius = 0.12
		horn_mesh.height = 0.46
		horn.mesh = horn_mesh
		horn.material_override = ember
		horn.position = Vector3(side * 0.19, 1.62, 0.0)
		horn.rotation.z = side * -0.28
		_visual_root.add_child(horn)
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.035
		eye_mesh.height = 0.07
		eye.mesh = eye_mesh
		eye.material_override = ember
		eye.position = Vector3(side * 0.1, 1.34, 0.29)
		_visual_root.add_child(eye)
	var sash := MeshInstance3D.new()
	var sash_mesh := CylinderMesh.new()
	sash_mesh.top_radius = 0.44
	sash_mesh.bottom_radius = 0.44
	sash_mesh.height = 0.11
	sash.mesh = sash_mesh
	sash.material_override = ArtPalette.material(Color("9e6042"), 0.76)
	sash.position.y = 0.48
	_visual_root.add_child(sash)
	for side in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		var leg_mesh := CylinderMesh.new()
		leg_mesh.top_radius = 0.1
		leg_mesh.bottom_radius = 0.13
		leg_mesh.height = 0.58
		leg.mesh = leg_mesh
		leg.material_override = dark
		leg.position = Vector3(side * 0.18, 0.22, 0.0)
		_visual_root.add_child(leg)
	var bar := MeshInstance3D.new()
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(0.82, 0.055, 0.045)
	bar.mesh = bar_mesh
	bar.material_override = ArtPalette.material(Color("243136"), 0.5)
	bar.position = Vector3(0, 1.88, 0)
	_visual_root.add_child(bar)
	_health_fill = MeshInstance3D.new()
	var fill_mesh := BoxMesh.new()
	fill_mesh.size = Vector3(0.78, 0.035, 0.025)
	_health_fill.mesh = fill_mesh
	_health_fill.material_override = ArtPalette.material(Color("de7860"), 0.42, 0.0, Color("b74337"), 0.8)
	_health_fill.position = Vector3(-0.39, 1.88, -0.03)
	_visual_root.add_child(_health_fill)
