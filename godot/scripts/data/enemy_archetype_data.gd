class_name EnemyArchetypeData
extends Resource

@export var id: StringName = &"stalker"
@export var display_name := "追影"
@export_multiline var design_note := ""
@export var model_slot: StringName = &"enemy_stalker"
@export var behavior: StringName = &"direct"
@export var max_hp := 64.0
@export var move_speed := 2.35
@export var acceleration := 5.5
@export var contact_damage := 9.0
@export var contact_cooldown := 0.68
@export var contact_range := 1.05
@export var radius := 0.48
@export var visual_scale := 1.0
@export var essence_reward := 1
@export_range(0.0, 10.0, 0.05) var spawn_weight := 1.0
@export_range(0.0, 1.0, 0.01) var unlock_intensity := 0.0

func is_valid() -> bool:
	return not id.is_empty() and max_hp > 0.0 and move_speed > 0.0 and radius > 0.0 and essence_reward > 0
