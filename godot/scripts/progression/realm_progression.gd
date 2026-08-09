class_name RealmProgression
extends Node

signal realm_changed(realm: Dictionary, selected_rule: Dictionary)
signal breakthrough_opened(from_realm: Dictionary, to_realm: Dictionary, options: Array[Dictionary])
signal breakthrough_closed
signal boss_gate_changed(name: String, current: float, maximum: float, visible: bool)

const RUNTIME_RULE_ADAPTERS := {
	"swordbone": "hit_echo",
	"thunderbase": "dash_chain",
	"purealtar": "cooldown_window",
	"swordcore": "periodic_sword",
	"thundercore": "thunder_mark_reserved",
	"mixedcore": "active_weapon_reserved",
	"swordbaby": "periodic_shadow",
	"thunderbaby": "fatal_guard_reserved",
	"spiritbaby": "threat_cast",
	"sworddomain": "sword_marks",
	"thunderdomain": "thunder_conduct_reserved",
	"destiny": "active_weapon_reserved",
	"taixu": "movement_nodes",
	"thunderpool": "dash_field",
	"voidreturn": "active_weapon_reserved"
}

var current_realm_index := 0
var selected_rules: Array[StringName] = []
var pending_options: Array[Dictionary] = []
var breakthrough_active := false
var defeated_bosses: Array[int] = []
var _next_boss_index := 0
var _last_second := -1
var _hit_counter := 0
var _enemy_sword_marks: Dictionary = {}
var _taixu_anchor := Vector3.ZERO
var _player: PlayerController
var _swords: SwordManager
var _director: EncounterDirector

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func configure(player: PlayerController, swords: SwordManager, director: EncounterDirector) -> void:
	_player = player
	_swords = swords
	_director = director
	_swords.enemy_hit.connect(_on_enemy_hit)
	_player.dash_started.connect(_on_dash_started)
	_director.boss_spawned.connect(_on_boss_spawned)
	_director.boss_health_changed.connect(_on_boss_health_changed)
	_director.boss_defeated.connect(_on_boss_defeated)
	_taixu_anchor = _player.global_position
	realm_changed.emit(current_realm(), {})

func _process(_delta: float) -> void:
	if not is_instance_valid(_director) or breakthrough_active:
		return
	var schedule := LegacyContentCatalog.list(&"boss_schedule_seconds")
	if _next_boss_index < schedule.size() and _director.elapsed >= float(schedule[_next_boss_index]):
		var spawned := _director.spawn_legacy_boss(_next_boss_index, LegacyContentCatalog.boss(_next_boss_index))
		if is_instance_valid(spawned) and spawned.boss_index == _next_boss_index:
			_next_boss_index += 1
	var second := floori(_director.elapsed)
	if second != _last_second:
		_last_second = second
		_run_second_hooks(second)

func current_realm() -> Dictionary:
	return LegacyContentCatalog.realm(current_realm_index)

func choose_breakthrough(index: int) -> bool:
	if not breakthrough_active or index < 0 or index >= pending_options.size():
		return false
	var selected := pending_options[index]
	selected_rules.append(StringName(selected.id))
	current_realm_index = mini(current_realm_index + 1, LegacyContentCatalog.list(&"realms").size() - 1)
	breakthrough_active = false
	pending_options.clear()
	get_tree().paused = false
	_apply_acquisition_rule(StringName(selected.id))
	realm_changed.emit(current_realm(), selected)
	breakthrough_closed.emit()
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not breakthrough_active or not event.is_pressed() or event.is_echo():
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.physical_keycode in [KEY_1, KEY_KP_1]:
			choose_breakthrough(0)
		elif key.physical_keycode in [KEY_2, KEY_KP_2]:
			choose_breakthrough(1)
		elif key.physical_keycode in [KEY_3, KEY_KP_3]:
			choose_breakthrough(2)

func reset_runtime() -> void:
	current_realm_index = 0
	selected_rules.clear()
	pending_options.clear()
	breakthrough_active = false
	defeated_bosses.clear()
	_next_boss_index = 0
	_last_second = -1
	_hit_counter = 0
	_enemy_sword_marks.clear()
	_taixu_anchor = _player.global_position if is_instance_valid(_player) else Vector3.ZERO
	realm_changed.emit(current_realm(), {})
	boss_gate_changed.emit("", 0.0, 1.0, false)

func snapshot() -> Dictionary:
	return {
		"current_realm_index": current_realm_index,
		"current_realm": current_realm().duplicate(true),
		"selected_rules": selected_rules.duplicate(),
		"breakthrough_active": breakthrough_active,
		"pending_option_ids": pending_options.map(func(option: Dictionary) -> String: return String(option.id)),
		"defeated_bosses": defeated_bosses.duplicate(),
		"next_boss_index": _next_boss_index,
		"runtime_rule_adapters": RUNTIME_RULE_ADAPTERS.duplicate(true)
	}

func force_boss_gate(index: int) -> EnemyController:
	_next_boss_index = maxi(_next_boss_index, index + 1)
	return _director.spawn_legacy_boss(index, LegacyContentCatalog.boss(index))

func _on_boss_spawned(_enemy: EnemyController, _index: int, boss_data: Dictionary) -> void:
	boss_gate_changed.emit(String(boss_data.get("name", "首领")), float(boss_data.get("hp", 1.0)), float(boss_data.get("hp", 1.0)), true)

func _on_boss_health_changed(name: String, current: float, maximum: float) -> void:
	boss_gate_changed.emit(name, current, maximum, true)

func _on_boss_defeated(index: int, _boss_data: Dictionary) -> void:
	defeated_bosses.append(index)
	boss_gate_changed.emit("", 0.0, 1.0, false)
	if current_realm_index >= LegacyContentCatalog.list(&"realms").size() - 1:
		return
	var next_realm := LegacyContentCatalog.realm(current_realm_index + 1)
	var milestone: Dictionary = next_realm.get("milestone", {}) as Dictionary
	if int(milestone.get("bossIndex", -1)) != index:
		return
	pending_options.clear()
	for rule_id: String in next_realm.get("choices", []):
		pending_options.append(LegacyContentCatalog.rule(StringName(rule_id)))
	breakthrough_active = not pending_options.is_empty()
	if breakthrough_active:
		get_tree().paused = true
		breakthrough_opened.emit(current_realm(), next_realm, pending_options)

func _apply_acquisition_rule(rule_id: StringName) -> void:
	match rule_id:
		&"purealtar":
			_swords.apply_upgrade(&"cooldown_reduction", 0.08)
		&"mixedcore":
			_swords.apply_upgrade(&"damage_multiplier", 0.08)
		&"destiny":
			_swords.apply_upgrade(&"cooldown_reduction", 0.1)
		&"voidreturn":
			_swords.apply_upgrade(&"damage_multiplier", 0.12)

func _on_enemy_hit(enemy: Node, _hit_count: int) -> void:
	_hit_counter += 1
	if &"swordbone" in selected_rules and _hit_counter % 5 == 0 and is_instance_valid(enemy):
		(enemy as EnemyController).take_damage(34.0, _player.global_position.direction_to((enemy as Node3D).global_position))
	if &"sworddomain" in selected_rules and is_instance_valid(enemy):
		var key := (enemy as EnemyController).enemy_id
		var marks := int(_enemy_sword_marks.get(key, 0)) + 1
		if marks >= 3:
			marks = 0
			_area_damage((enemy as Node3D).global_position, 42.0, 2.8, 5)
		_enemy_sword_marks[key] = marks

func _on_dash_started(_direction: Vector3) -> void:
	if &"thunderbase" in selected_rules:
		_strike_nearest(30.0, 3)
	if &"thunderpool" in selected_rules:
		_area_damage(_player.global_position, 28.0, 2.8, 8)

func _run_second_hooks(second: int) -> void:
	if second <= 0:
		return
	if &"swordcore" in selected_rules and second % 7 == 0:
		_strike_nearest(38.0, 1)
	if &"swordbaby" in selected_rules and second % 8 == 0:
		_strike_nearest(44.0, 1)
	if &"spiritbaby" in selected_rules and second % 12 == 0:
		_strike_nearest(52.0, 1)
	if &"taixu" in selected_rules and _player.global_position.distance_to(_taixu_anchor) >= 2.4:
		_taixu_anchor = _player.global_position
		_area_damage(_taixu_anchor, 32.0, 2.4, 6)

func _strike_nearest(damage: float, limit: int) -> void:
	var candidates: Array[Node] = get_tree().get_nodes_in_group("enemies")
	candidates.sort_custom(func(a: Node, b: Node) -> bool:
		return _player.global_position.distance_squared_to((a as Node3D).global_position) < _player.global_position.distance_squared_to((b as Node3D).global_position)
	)
	for index in mini(limit, candidates.size()):
		var enemy := candidates[index] as EnemyController
		if is_instance_valid(enemy):
			enemy.take_damage(damage, _player.global_position.direction_to(enemy.global_position))

func _area_damage(center: Vector3, damage: float, radius: float, limit: int) -> void:
	var hits := 0
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if hits >= limit:
			break
		if not is_instance_valid(node):
			continue
		var enemy := node as EnemyController
		if enemy.global_position.distance_to(center) <= radius:
			enemy.take_damage(damage, center.direction_to(enemy.global_position))
			hits += 1
