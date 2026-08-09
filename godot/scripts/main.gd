extends Node3D

const SwordManagerScript := preload("res://scripts/combat/sword_manager.gd")
const DirectorScript := preload("res://scripts/enemies/encounter_director.gd")
const ProgressionScript := preload("res://scripts/progression/run_progression.gd")
const FeedbackScript := preload("res://scripts/effects/combat_feedback.gd")

@onready var level: LevelBuilder = $World
@onready var player: PlayerController = $Actors/Player
@onready var camera_rig: FollowCamera = $CameraRig
@onready var hud: GameHUD = $HUD/GameHUD

var sword_manager: SwordManager
var director: EncounterDirector
var progression: RunProgression
var feedback: CombatFeedback
var debug_mode := false
var run_over := false
var run_seed := 9271

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameEvents.begin_run(run_seed)
	_create_runtime_systems()
	_connect_runtime_signals()
	hud.configure(self, player, sword_manager, director, progression)
	_on_region_changed("ruins")

func _create_runtime_systems() -> void:
	sword_manager = SwordManagerScript.new()
	sword_manager.name = "SwordManager"
	$Actors.add_child(sword_manager)
	sword_manager.configure(player)
	director = DirectorScript.new()
	director.name = "EncounterDirector"
	add_child(director)
	director.configure(player, level)
	feedback = FeedbackScript.new()
	feedback.name = "CombatFeedback"
	add_child(feedback)
	feedback.configure(camera_rig)
	progression = ProgressionScript.new()
	progression.name = "RunProgression"
	add_child(progression)
	progression.configure(player, sword_manager, director, run_seed)

func _connect_runtime_signals() -> void:
	director.enemy_count_changed.connect(_on_runtime_changed)
	director.region_changed.connect(_on_region_changed)
	director.damage_taken.connect(_on_damage_taken)
	director.enemy_defeated.connect(_on_enemy_defeated)
	director.phase_changed.connect(_on_phase_changed)
	player.health_changed.connect(_on_player_health_changed)
	player.distance_changed.connect(_on_player_distance_changed)
	player.damage_taken.connect(_on_player_damage_feedback)
	player.dash_started.connect(_on_dash_started)
	player.died.connect(_on_player_died)
	sword_manager.metrics_changed.connect(_on_sword_metrics)
	sword_manager.impact.connect(feedback.play_sword_impact)
	progression.progression_changed.connect(_on_progression_changed)
	progression.draft_opened.connect(_on_draft_changed)
	progression.draft_closed.connect(_on_draft_closed)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		_reset_runtime()
	if Input.is_action_just_pressed("toggle_debug"):
		debug_mode = not debug_mode
		hud.set_debug_visible(debug_mode)
	if not progression.draft_active and not run_over:
		if Input.is_key_pressed(KEY_1):
			director.set_debug_count(1)
		if Input.is_key_pressed(KEY_3):
			director.set_debug_count(3)
		if Input.is_key_pressed(KEY_8):
			director.set_debug_count(8)
	hud.queue_redraw()

func _reset_runtime() -> void:
	get_tree().paused = false
	run_over = false
	GameEvents.reset_run()
	GameEvents.begin_run(run_seed)
	progression.reset_runtime(run_seed)
	player.reset_runtime()
	director.reset_runtime()
	sword_manager.reset_runtime()
	feedback.reset_runtime()
	camera_rig.reset_runtime()
	_on_region_changed("ruins")

func _on_enemy_defeated(_enemy: EnemyController, _archetype_id: StringName, reward: int) -> void:
	progression.grant_essence(reward)
	hud.queue_redraw()

func _on_player_damage_feedback(amount: float) -> void:
	feedback.play_player_damage(player.global_position, amount)

func _on_dash_started(_direction: Vector3) -> void:
	camera_rig.add_trauma(0.05)

func _on_player_died() -> void:
	run_over = true
	get_tree().paused = true
	hud.queue_redraw()

func _on_sword_metrics(_shots: int, _hits: int, _multi: int) -> void:
	hud.queue_redraw()

func _on_runtime_changed(_value := 0) -> void:
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

func _on_phase_changed(_phase_id: StringName, _intensity: float, _target: int) -> void:
	hud.queue_redraw()

func _on_progression_changed(_level: int, _essence: int, _next: int) -> void:
	hud.queue_redraw()

func _on_draft_changed(_options: Array[UpgradeDefinition]) -> void:
	hud.queue_redraw()

func _on_draft_closed() -> void:
	hud.queue_redraw()

func debug_snapshot() -> Dictionary:
	return {
		"engine": "Godot 4.7.1",
		"branch_gate": "V10_CORE_GAMEPLAY_FRAMEWORK",
		"region": director.current_region,
		"run_over": run_over,
		"player_hp": player.hp,
		"player_distance": player.total_distance,
		"damage_taken": director.damage_taken_total,
		"encounter": director.snapshot(),
		"combat": sword_manager.snapshot(),
		"progression": progression.snapshot(),
		"world": level.snapshot(),
		"qingyao": player._visual.snapshot(),
		"feedback_pool_size": feedback._pool.size(),
		"rodin_assets": RodinAssetRegistry.audit_slots()
	}
