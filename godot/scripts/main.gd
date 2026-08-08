extends Node3D

const SwordManagerScript := preload("res://scripts/combat/sword_manager.gd")
const DirectorScript := preload("res://scripts/enemies/encounter_director.gd")

@onready var level := $World
@onready var player: PlayerController = $Actors/Player
@onready var camera_rig := $CameraRig
@onready var hud := $HUD/GameHUD

var sword_manager: SwordManager
var director: EncounterDirector
var debug_mode := false

func _ready() -> void:
	sword_manager = SwordManagerScript.new()
	sword_manager.name = "SwordManager"
	$Actors.add_child(sword_manager)
	sword_manager.configure(player)
	director = DirectorScript.new()
	director.name = "EncounterDirector"
	add_child(director)
	director.configure(player, level)
	director.enemy_count_changed.connect(_on_runtime_changed)
	director.region_changed.connect(_on_region_changed)
	director.damage_taken.connect(_on_damage_taken)
	player.health_changed.connect(_on_player_health_changed)
	player.distance_changed.connect(_on_player_distance_changed)
	sword_manager.metrics_changed.connect(_on_sword_metrics)
	hud.configure(self, player, sword_manager, director)
	_on_region_changed("ruins")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		_reset_runtime()
	if Input.is_action_just_pressed("toggle_debug"):
		debug_mode = not debug_mode
		hud.set_debug_visible(debug_mode)
	if Input.is_key_pressed(KEY_1):
		director.set_debug_count(1)
	if Input.is_key_pressed(KEY_3):
		director.set_debug_count(3)
	if Input.is_key_pressed(KEY_8):
		director.set_debug_count(8)
	hud.queue_redraw()

func _reset_runtime() -> void:
	player.reset_runtime()
	director.reset_runtime()
	sword_manager.reset_runtime()
	_on_region_changed("ruins")

func _on_sword_metrics(_shots: int, _hits: int, _multi: int) -> void:
	hud.queue_redraw()

func _on_runtime_changed(_value = 0) -> void:
	hud.queue_redraw()

func _on_damage_taken(_amount: float) -> void:
	hud.queue_redraw()

func _on_player_health_changed(_current: float, _maximum: float) -> void:
	hud.queue_redraw()

func _on_player_distance_changed(_total: float) -> void:
	hud.queue_redraw()

func _on_region_changed(region_id: String) -> void:
	hud.set_region(region_id)
	hud.queue_redraw()

func debug_snapshot() -> Dictionary:
	return {
		"engine": "Godot 4.7.1",
		"region": director.current_region,
		"enemy_count": director.enemies.size(),
		"player_hp": player.hp,
		"shots_fired": sword_manager.shots_fired,
		"hits": sword_manager.hits,
		"avg_hits_per_shot": sword_manager.average_hits_per_shot(),
		"multi_hit_rate": sword_manager.multi_hit_rate(),
		"player_distance": player.total_distance,
		"damage_taken": director.damage_taken_total
	}
