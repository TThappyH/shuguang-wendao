class_name EncounterDirector
extends Node

signal enemy_count_changed(count: int)
signal enemy_defeated(enemy: EnemyController, archetype_id: StringName, essence_reward: int)
signal damage_taken(amount: float)
signal region_changed(region_id: String)
signal phase_changed(phase_id: StringName, intensity: float, target_count: int)
signal boss_spawned(enemy: EnemyController, boss_index: int, boss_data: Dictionary)
signal boss_health_changed(name: String, current: float, maximum: float)
signal boss_defeated(boss_index: int, boss_data: Dictionary)

const STALKER: EnemyArchetypeData = preload("res://data/enemies/stalker.tres")
const SKIRMISHER: EnemyArchetypeData = preload("res://data/enemies/skirmisher.tres")
const BULWARK: EnemyArchetypeData = preload("res://data/enemies/bulwark.tres")
const EnemyScript := preload("res://scripts/enemies/enemy_controller.gd")

const PHASES := [
	{"id": &"WARMUP", "start": 0.0, "intensity": 0.16, "target": 1, "spawn_interval": 0.74},
	{"id": &"BUILD", "start": 16.0, "intensity": 0.36, "target": 3, "spawn_interval": 0.52},
	{"id": &"PRESSURE", "start": 38.0, "intensity": 0.62, "target": 5, "spawn_interval": 0.38},
	{"id": &"SURGE", "start": 68.0, "intensity": 0.9, "target": 8, "spawn_interval": 0.28},
	{"id": &"RECOVER", "start": 92.0, "intensity": 0.42, "target": 4, "spawn_interval": 0.6}
]
const CYCLE_DURATION := 108.0

var player: PlayerController
var level: Node
var enemies: Array[EnemyController] = []
var spawn_serial := 0
var total_spawned := 0
var peak_enemies := 0
var elapsed := 0.0
var kills := 0
var damage_taken_total := 0.0
var current_region := "ruins"
var current_phase: StringName = &"WARMUP"
var phase_intensity := 0.16
var _spawn_target := 1
var _spawn_interval := 0.74
var _spawn_clock := 0.1
var _started := false
var _debug_target := 0
var _last_reported_count := -1
var _rng := RandomNumberGenerator.new()
var _pressure_relief := 0.0
var active_boss: EnemyController
var active_boss_index := -1
var active_boss_data: Dictionary = {}

func configure(owner_player: PlayerController, owner_level: Node) -> void:
	player = owner_player
	level = owner_level
	_rng.seed = GameEvents.run_seed + 311
	_started = true
	_apply_phase(PHASES[0])

func _process(delta: float) -> void:
	if not _started or not is_instance_valid(player):
		return
	elapsed += delta
	_spawn_clock -= delta
	_prune_invalid_enemies()
	_update_region()
	_update_phase()
	var target := _effective_target()
	if _spawn_clock <= 0.0 and enemies.size() < target:
		_spawn_one()
		_spawn_clock = 0.16 if _debug_target > 0 else _spawn_interval
	peak_enemies = maxi(peak_enemies, enemies.size())
	_notify_count_if_changed()

func set_debug_count(target: int) -> void:
	_debug_target = clampi(target, 1, 8)
	_spawn_clock = 0.02
	while enemies.size() > _debug_target:
		var enemy: EnemyController = enemies.pop_back()
		if is_instance_valid(enemy):
			enemy.queue_free()
	_notify_count_if_changed()

func clear_debug_count() -> void:
	_debug_target = 0
	_spawn_clock = 0.02

func apply_upgrade(stat: StringName, amount: float) -> void:
	match stat:
		&"pressure_relief":
			_pressure_relief = clampf(_pressure_relief + amount, 0.0, 0.4)
		_:
			push_warning("Unknown director upgrade stat: %s" % stat)

func reset_runtime() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	kills = 0
	damage_taken_total = 0.0
	elapsed = 0.0
	spawn_serial = 0
	total_spawned = 0
	peak_enemies = 0
	current_region = "ruins"
	_debug_target = 0
	_pressure_relief = 0.0
	active_boss = null
	active_boss_index = -1
	active_boss_data = {}
	_spawn_clock = 0.1
	_last_reported_count = -1
	_rng.seed = GameEvents.run_seed + 311
	_apply_phase(PHASES[0])
	_notify_count_if_changed()

func snapshot() -> Dictionary:
	return {
		"phase": String(current_phase),
		"intensity": phase_intensity,
		"target_count": _effective_target(),
		"enemy_count": enemies.size(),
		"peak_enemies": peak_enemies,
		"total_spawned": total_spawned,
		"kills": kills,
		"damage_taken": damage_taken_total,
		"debug_target": _debug_target,
		"active_boss": active_boss.snapshot() if is_instance_valid(active_boss) else {}
	}

func spawn_legacy_boss(index: int, boss_data: Dictionary) -> EnemyController:
	if is_instance_valid(active_boss) or boss_data.is_empty():
		return active_boss
	var data := EnemyArchetypeData.new()
	data.id = StringName("legacy_boss_%d" % index)
	data.display_name = String(boss_data.get("name", "首领"))
	data.design_note = String(boss_data.get("title", "HTML V6.7 Boss migration"))
	data.model_slot = &""
	data.behavior = &"direct"
	data.max_hp = float(boss_data.get("hp", 2200.0))
	data.move_speed = float(boss_data.get("speed", 1.4))
	data.acceleration = 4.2
	data.contact_damage = float(boss_data.get("dmg", 30.0))
	data.contact_cooldown = 0.92
	data.contact_range = 1.45
	data.radius = float(boss_data.get("r", 1.0))
	data.visual_scale = maxf(1.35, data.radius * 1.35)
	data.essence_reward = maxi(8, roundi(float(boss_data.get("xp", 220.0)) / 30.0))
	var enemy := EnemyScript.new() as EnemyController
	spawn_serial += 1
	enemy.name = "Boss_%02d_%s" % [index + 1, data.display_name]
	enemy.position = _find_spawn_point()
	enemy.configure(player, level, spawn_serial, data, 1.0)
	enemy.configure_as_boss(index, data.display_name)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.contact_damage.connect(_on_contact_damage)
	enemy.health_changed.connect(_on_boss_health_changed)
	add_child(enemy)
	enemies.append(enemy)
	active_boss = enemy
	active_boss_index = index
	active_boss_data = boss_data.duplicate(true)
	total_spawned += 1
	boss_spawned.emit(enemy, index, active_boss_data)
	boss_health_changed.emit(enemy.display_name, enemy.hp, enemy.max_hp)
	return enemy

func _update_phase() -> void:
	if _debug_target > 0:
		return
	var cycle_time := fmod(elapsed, CYCLE_DURATION)
	var selected: Dictionary = PHASES[0]
	for phase: Dictionary in PHASES:
		if cycle_time >= float(phase.start):
			selected = phase
	_apply_phase(selected)

func _apply_phase(phase: Dictionary) -> void:
	var next_id: StringName = phase.id
	var changed := next_id != current_phase or not is_equal_approx(phase_intensity, float(phase.intensity))
	current_phase = next_id
	phase_intensity = float(phase.intensity)
	_spawn_target = int(phase.target)
	_spawn_interval = float(phase.spawn_interval) * (1.0 + _pressure_relief)
	if changed:
		phase_changed.emit(current_phase, phase_intensity, _spawn_target)
		GameEvents.encounter_phase_changed.emit(current_phase, phase_intensity, _spawn_target)

func _effective_target() -> int:
	if _debug_target > 0:
		return _debug_target
	var low_health_relief := 1 if player != null and player.hp / maxf(player.max_hp, 1.0) < 0.28 else 0
	return maxi(1, _spawn_target - low_health_relief)

func _spawn_one() -> void:
	var data := _choose_archetype()
	var enemy := EnemyScript.new() as EnemyController
	spawn_serial += 1
	enemy.name = "%s_%03d" % [String(data.id), spawn_serial]
	enemy.position = _find_spawn_point()
	var difficulty := 1.0 + floorf(elapsed / CYCLE_DURATION) * 0.08
	enemy.configure(player, level, spawn_serial, data, difficulty)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.contact_damage.connect(_on_contact_damage)
	add_child(enemy)
	enemies.append(enemy)
	total_spawned += 1
	peak_enemies = maxi(peak_enemies, enemies.size())
	GameEvents.enemy_spawned.emit(enemy, data.id)

func _choose_archetype() -> EnemyArchetypeData:
	var eligible: Array[EnemyArchetypeData] = []
	for data in [STALKER, SKIRMISHER, BULWARK]:
		if phase_intensity >= data.unlock_intensity:
			eligible.append(data)
	var total_weight := 0.0
	for data in eligible:
		total_weight += data.spawn_weight
	var roll := _rng.randf() * total_weight
	for data in eligible:
		roll -= data.spawn_weight
		if roll <= 0.0:
			return data
	return eligible.back()

func _find_spawn_point() -> Vector3:
	var angle := float(spawn_serial) * 2.399 + _rng.randf_range(-0.2, 0.2)
	var distance := _rng.randf_range(9.2, 13.0)
	var candidate := player.global_position + Vector3(cos(angle) * distance, 0.08, sin(angle) * distance)
	if WorldConfig.is_walkable(candidate, 0.6):
		return candidate
	var fallback := Vector3(0.0, 0.08, -8.0)
	return fallback if WorldConfig.is_walkable(fallback, 0.6) else Vector3(4.0, 0.08, 4.0)

func _on_enemy_defeated(enemy: EnemyController) -> void:
	kills += 1
	enemies.erase(enemy)
	var data := enemy.archetype
	var archetype_id: StringName = data.id if data != null else &"fallback"
	var reward := data.essence_reward if data != null else 1
	enemy_defeated.emit(enemy, archetype_id, reward)
	GameEvents.enemy_defeated.emit(enemy, archetype_id, reward)
	if enemy.is_boss:
		var defeated_index := enemy.boss_index
		var defeated_data := active_boss_data.duplicate(true)
		active_boss = null
		active_boss_index = -1
		active_boss_data = {}
		boss_defeated.emit(defeated_index, defeated_data)
	_notify_count_if_changed()

func _on_boss_health_changed(enemy: EnemyController, current: float, maximum: float) -> void:
	if enemy == active_boss:
		boss_health_changed.emit(enemy.display_name, current, maximum)

func _on_contact_damage(amount: float) -> void:
	if player.take_contact_damage(amount):
		damage_taken_total += amount
		damage_taken.emit(amount)

func _update_region() -> void:
	var next_region := WorldConfig.region_for_position(player.global_position)
	if next_region != current_region:
		current_region = next_region
		region_changed.emit(current_region)

func _prune_invalid_enemies() -> void:
	for index in range(enemies.size() - 1, -1, -1):
		if not is_instance_valid(enemies[index]):
			enemies.remove_at(index)

func _notify_count_if_changed() -> void:
	if enemies.size() == _last_reported_count:
		return
	_last_reported_count = enemies.size()
	enemy_count_changed.emit(_last_reported_count)
