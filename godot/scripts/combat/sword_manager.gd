class_name SwordManager
extends Node3D

signal metrics_changed(shots: int, hits: int, multi_hit_shots: int)
signal impact(world_position: Vector3, hit_count: int, damage: float)

var player: Node3D
var shots_fired := 0
var hits := 0
var multi_hit_shots := 0
var swords: Array[FlyingSword] = []
var damage_multiplier := 1.0
var travel_speed_multiplier := 1.0
var penetration_bonus := 0.0
var cooldown_multiplier := 1.0
var penetration_stacks := 0

func configure(owner_player: Node3D) -> void:
	player = owner_player
	for index in 3:
		var sword := FlyingSword.new()
		sword.name = "FlyingSword%d" % (index + 1)
		add_child(sword)
		sword.configure(player, index)
		sword.shot_fired.connect(_on_shot_fired)
		sword.hit_registered.connect(_on_hit_registered)
		sword.multi_hit_completed.connect(_on_multi_hit_completed)
		sword.impact.connect(_on_impact)
		swords.append(sword)
	_apply_tuning_to_swords()

func _on_shot_fired() -> void:
	shots_fired += 1
	metrics_changed.emit(shots_fired, hits, multi_hit_shots)

func _on_hit_registered(_enemy: Node, _hit_count: int) -> void:
	hits += 1
	metrics_changed.emit(shots_fired, hits, multi_hit_shots)

func _on_multi_hit_completed(_hit_count: int) -> void:
	multi_hit_shots += 1
	metrics_changed.emit(shots_fired, hits, multi_hit_shots)

func _on_impact(world_position: Vector3, hit_count: int, dealt_damage: float) -> void:
	impact.emit(world_position, hit_count, dealt_damage)

func apply_upgrade(stat: StringName, amount: float) -> void:
	match stat:
		&"damage_multiplier":
			damage_multiplier += amount
		&"travel_speed_multiplier":
			travel_speed_multiplier += amount
		&"penetration_distance":
			penetration_bonus += amount
			penetration_stacks += 1
		&"cooldown_reduction":
			cooldown_multiplier = maxf(0.55, cooldown_multiplier * (1.0 - amount))
		_:
			push_warning("Unknown sword upgrade stat: %s" % stat)
	_apply_tuning_to_swords()

func _apply_tuning_to_swords() -> void:
	for sword in swords:
		sword.damage = 34.0 * damage_multiplier
		sword.speed = 18.0 * travel_speed_multiplier
		sword.penetration_distance = 8.0 + penetration_bonus
		sword.max_hits = 3 if penetration_stacks >= 3 else 2
		sword.reform_cooldown = 0.72 * cooldown_multiplier

func reset_runtime() -> void:
	damage_multiplier = 1.0
	travel_speed_multiplier = 1.0
	penetration_bonus = 0.0
	cooldown_multiplier = 1.0
	penetration_stacks = 0
	shots_fired = 0
	hits = 0
	multi_hit_shots = 0
	_apply_tuning_to_swords()
	for sword in swords:
		sword.reset_runtime()
	metrics_changed.emit(0, 0, 0)

func snapshot() -> Dictionary:
	return {
		"shots_fired": shots_fired,
		"hits": hits,
		"multi_hit_shots": multi_hit_shots,
		"avg_hits_per_shot": average_hits_per_shot(),
		"multi_hit_rate": multi_hit_rate(),
		"damage_multiplier": damage_multiplier,
		"travel_speed_multiplier": travel_speed_multiplier,
		"penetration_bonus": penetration_bonus,
		"max_hits": 3 if penetration_stacks >= 3 else 2
	}

func average_hits_per_shot() -> float:
	return float(hits) / float(maxi(1, shots_fired))

func multi_hit_rate() -> float:
	return float(multi_hit_shots) / float(maxi(1, shots_fired))
