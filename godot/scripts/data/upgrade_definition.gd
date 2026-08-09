class_name UpgradeDefinition
extends Resource

@export var id: StringName = &"sword_edge"
@export var title := "剑锋淬灵"
@export_multiline var description := "飞剑伤害提高。"
@export var target: StringName = &"sword"
@export var stat: StringName = &"damage_multiplier"
@export var amount := 0.15
@export_range(1, 9, 1) var max_stacks := 5
@export_range(0.1, 10.0, 0.1) var draft_weight := 1.0
@export var accent := Color("6ed7ca")

func is_valid() -> bool:
	return not id.is_empty() and not title.is_empty() and not target.is_empty() and not stat.is_empty() and max_stacks > 0
