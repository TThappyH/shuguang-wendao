class_name RunProgression
extends Node

signal progression_changed(level: int, essence: int, next_level_essence: int)
signal draft_opened(options: Array[UpgradeDefinition])
signal draft_closed
signal upgrade_applied(definition: UpgradeDefinition, stack_count: int)

const UPGRADE_PATHS := [
	"res://data/upgrades/sword_edge.tres",
	"res://data/upgrades/sword_velocity.tres",
	"res://data/upgrades/deep_penetration.tres",
	"res://data/upgrades/formation_cycle.tres",
	"res://data/upgrades/vital_breath.tres",
	"res://data/upgrades/cloud_step.tres"
]

var level := 1
var essence := 0
var next_level_essence := 4
var total_essence := 0
var stacks: Dictionary = {}
var current_options: Array[UpgradeDefinition] = []
var draft_active := false
var run_seed := 9271
var _queued_drafts := 0
var _player: PlayerController
var _swords: SwordManager
var _director: EncounterDirector
var _catalog: Array[UpgradeDefinition] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_catalog()

func configure(player: PlayerController, swords: SwordManager, director: EncounterDirector, seed := 9271) -> void:
	_player = player
	_swords = swords
	_director = director
	run_seed = seed
	progression_changed.emit(level, essence, next_level_essence)

func grant_essence(amount: int) -> void:
	if amount <= 0:
		return
	essence += amount
	total_essence += amount
	while essence >= next_level_essence:
		essence -= next_level_essence
		level += 1
		next_level_essence = 4 + (level - 1) * 3
		_queued_drafts += 1
	progression_changed.emit(level, essence, next_level_essence)
	GameEvents.progression_changed.emit(level, essence, next_level_essence)
	if _queued_drafts > 0 and not draft_active:
		_open_next_draft()

func choose(index: int) -> bool:
	if not draft_active or index < 0 or index >= current_options.size():
		return false
	var definition := current_options[index]
	var count := int(stacks.get(definition.id, 0)) + 1
	stacks[definition.id] = count
	_apply(definition)
	draft_active = false
	current_options.clear()
	get_tree().paused = false
	upgrade_applied.emit(definition, count)
	draft_closed.emit()
	GameEvents.upgrade_selected.emit(definition.id, count)
	if _queued_drafts > 0:
		call_deferred("_open_next_draft")
	return true

func reset_runtime(seed := 9271) -> void:
	get_tree().paused = false
	level = 1
	essence = 0
	next_level_essence = 4
	total_essence = 0
	stacks.clear()
	current_options.clear()
	draft_active = false
	_queued_drafts = 0
	run_seed = seed
	progression_changed.emit(level, essence, next_level_essence)

func snapshot() -> Dictionary:
	return {
		"level": level,
		"essence": essence,
		"next_level_essence": next_level_essence,
		"total_essence": total_essence,
		"draft_active": draft_active,
		"upgrade_stacks": stacks.duplicate(true)
	}

func _unhandled_input(event: InputEvent) -> void:
	if not draft_active or not event.is_pressed() or event.is_echo():
		return
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.physical_keycode in [KEY_1, KEY_KP_1]:
			choose(0)
		elif key.physical_keycode in [KEY_2, KEY_KP_2]:
			choose(1)
		elif key.physical_keycode in [KEY_3, KEY_KP_3]:
			choose(2)

func _load_catalog() -> void:
	_catalog.clear()
	for path in UPGRADE_PATHS:
		var resource := load(path)
		if resource is UpgradeDefinition and (resource as UpgradeDefinition).is_valid():
			_catalog.append(resource as UpgradeDefinition)
	if _catalog.size() < 3:
		push_error("Upgrade catalog requires at least three valid definitions")

func _open_next_draft() -> void:
	if _queued_drafts <= 0 or draft_active:
		return
	_queued_drafts -= 1
	current_options = _draft_options()
	if current_options.is_empty():
		return
	draft_active = true
	get_tree().paused = true
	draft_opened.emit(current_options)
	GameEvents.upgrade_draft_opened.emit(current_options)

func _draft_options() -> Array[UpgradeDefinition]:
	var eligible: Array[UpgradeDefinition] = []
	for definition in _catalog:
		if int(stacks.get(definition.id, 0)) < definition.max_stacks:
			eligible.append(definition)
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed + level * 7919 + total_essence * 131
	var result: Array[UpgradeDefinition] = []
	while not eligible.is_empty() and result.size() < 3:
		var total_weight := 0.0
		for item in eligible:
			total_weight += item.draft_weight
		var roll := rng.randf() * total_weight
		var selected_index := eligible.size() - 1
		for index in eligible.size():
			roll -= eligible[index].draft_weight
			if roll <= 0.0:
				selected_index = index
				break
		result.append(eligible[selected_index])
		eligible.remove_at(selected_index)
	return result

func _apply(definition: UpgradeDefinition) -> void:
	match definition.target:
		&"player":
			_player.apply_upgrade(definition.stat, definition.amount)
		&"sword":
			_swords.apply_upgrade(definition.stat, definition.amount)
		&"director":
			_director.apply_upgrade(definition.stat, definition.amount)
		_:
			push_warning("Unknown upgrade target: %s" % definition.target)
