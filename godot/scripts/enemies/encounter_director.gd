class_name EncounterDirector
extends Node

signal enemy_count_changed(count: int)
signal damage_taken(amount: float)
signal region_changed(region_id: String)

var player: PlayerController
var level: Node
var enemy_scene_script := preload("res://scripts/enemies/enemy_controller.gd")
var enemies: Array[EnemyController] = []
var spawn_serial := 0
var elapsed := 0.0
var kills := 0
var damage_taken_total := 0.0
var current_region := "ruins"
var _spawn_target := 1
var _wave_clock := 1.0
var _started := false

func configure(owner_player: PlayerController, owner_level: Node) -> void:
	player = owner_player
	level = owner_level
	_started = true
	_set_spawn_target(1)

func _process(delta: float) -> void:
	if not _started or not is_instance_valid(player):
		return
	elapsed += delta
	_wave_clock -= delta
	var next_region := WorldConfig.region_for_position(player.global_position)
	if next_region != current_region:
		current_region = next_region
		region_changed.emit(current_region)
	if _wave_clock <= 0.0 and enemies.size() < _spawn_target:
		_spawn_one()
		_wave_clock = 0.34
	if elapsed > 18.0 and _spawn_target == 1:
		_set_spawn_target(3)
	if elapsed > 42.0 and _spawn_target == 3:
		_set_spawn_target(8)
	enemy_count_changed.emit(enemies.size())

func _set_spawn_target(target: int) -> void:
	_spawn_target = target
	_wave_clock = 0.1

func set_debug_count(target: int) -> void:
	_set_spawn_target(clampi(target, 1, 8))
	while enemies.size() > _spawn_target:
		var enemy: EnemyController = enemies.pop_back()
		if is_instance_valid(enemy):
			enemy.queue_free()

func _spawn_one() -> void:
	if not is_instance_valid(player):
		return
	var spawn := _find_spawn_point()
	var enemy := enemy_scene_script.new() as EnemyController
	spawn_serial += 1
	enemy.name = "ChasingSpirit_%02d" % spawn_serial
	enemy.position = spawn
	add_child(enemy)
	enemy.hp = 52.0 + float((spawn_serial - 1) % 3) * 14.0
	enemy.move_speed = 2.35 + float((spawn_serial - 1) % 3) * 0.12
	enemy.contact_damage_value = 8.0 + float((spawn_serial - 1) % 3) * 1.5
	enemy.configure(player, level, spawn_serial, 1.0)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.contact_damage.connect(_on_contact_damage)
	enemies.append(enemy)

func _find_spawn_point() -> Vector3:
	var angle := float(spawn_serial) * 2.399
	var distance := 9.5 + float(spawn_serial % 3) * 1.7
	var candidate := player.global_position + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
	if WorldConfig.is_walkable(candidate, 0.5):
		return candidate
	var fallback := Vector3(0.0, 0.08, -8.0)
	return fallback if WorldConfig.is_walkable(fallback, 0.5) else Vector3(4.0, 0.08, 4.0)

func _on_enemy_defeated(enemy: Node) -> void:
	kills += 1
	enemies.erase(enemy)
	enemy_count_changed.emit(enemies.size())

func _on_contact_damage(amount: float) -> void:
	if player.take_contact_damage(amount):
		damage_taken_total += amount
		damage_taken.emit(amount)

func reset_runtime() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	kills = 0
	damage_taken_total = 0.0
	elapsed = 0.0
	spawn_serial = 0
	current_region = "ruins"
	_set_spawn_target(1)
