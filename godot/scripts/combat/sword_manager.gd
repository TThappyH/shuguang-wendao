class_name SwordManager
extends Node3D

signal metrics_changed(shots: int, hits: int, multi_hit_shots: int)

var player: Node3D
var shots_fired := 0
var hits := 0
var multi_hit_shots := 0
var swords: Array[FlyingSword] = []

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
		swords.append(sword)

func _on_shot_fired() -> void:
	shots_fired += 1
	metrics_changed.emit(shots_fired, hits, multi_hit_shots)

func _on_hit_registered(_enemy: Node, _hit_count: int) -> void:
	hits += 1
	metrics_changed.emit(shots_fired, hits, multi_hit_shots)

func _on_multi_hit_completed(_hit_count: int) -> void:
	multi_hit_shots += 1
	metrics_changed.emit(shots_fired, hits, multi_hit_shots)

func reset_runtime() -> void:
	shots_fired = 0
	hits = 0
	multi_hit_shots = 0
	metrics_changed.emit(0, 0, 0)

func average_hits_per_shot() -> float:
	return float(hits) / float(maxi(1, shots_fired))

func multi_hit_rate() -> float:
	return float(multi_hit_shots) / float(maxi(1, shots_fired))
