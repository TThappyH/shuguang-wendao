extends Node

signal run_started(seed: int)
signal run_reset
signal encounter_phase_changed(phase_id: StringName, intensity: float, target_count: int)
signal enemy_spawned(enemy: Node, archetype_id: StringName)
signal enemy_defeated(enemy: Node, archetype_id: StringName, essence: int)
signal player_damaged(amount: float, remaining_hp: float)
signal sword_impact(position: Vector3, hit_count: int, damage: float)
signal progression_changed(level: int, essence: int, next_level_essence: int)
signal upgrade_draft_opened(options: Array)
signal upgrade_selected(upgrade_id: StringName, stack_count: int)
signal feedback_requested(kind: StringName, position: Vector3, intensity: float)

var run_seed := 9271

func begin_run(seed: int = 9271) -> void:
	run_seed = seed
	run_started.emit(seed)

func reset_run() -> void:
	run_reset.emit()
