extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("main scene did not load")
		quit(1)
		return
	var main := packed.instantiate()
	root.add_child(main)
	current_scene = main
	await create_timer(3.2).timeout
	var snapshot: Dictionary = main.debug_snapshot()
	print("GODOT_SMOKE_SNAPSHOT=" + JSON.stringify(snapshot))
	var failures: Array[String] = []
	if snapshot.get("engine", "") != "Godot 4.7.1":
		failures.append("engine")
	var encounter: Dictionary = snapshot.get("encounter", {})
	var world: Dictionary = snapshot.get("world", {})
	if encounter.get("enemy_count", 0) < 1:
		failures.append("enemy_spawn")
	if not main.player._visual.loaded:
		failures.append("qingyao_glb")
	if not world.get("external_map_loaded", false) and world.get("fallback_blockers", 0) < 20:
		failures.append("world_geometry")
	if world.get("navigation_profile", "") != "FIVE_REGION_GRAPH" or world.get("gameplay_collision_proxies", 0) < WorldConfig.BLOCKERS.size():
		failures.append("world_gameplay_collision")
	if snapshot.get("feedback_pool_size", 0) != 24:
		failures.append("feedback_pool")
	if snapshot.get("rodin_assets", []).size() < 5:
		failures.append("rodin_registry")
	var camera: Dictionary = snapshot.get("camera", {})
	if float(camera.get("pitch_degrees", 0.0)) < 55.0 or float(camera.get("pitch_degrees", 0.0)) > 60.0:
		failures.append("gameplay_camera")
	var hud: Dictionary = snapshot.get("hud", {})
	if not hud.get("structured_controls", false):
		failures.append("structured_hud")
	if failures.is_empty():
		print("GODOT_SMOKE_PASS")
		quit(0)
	else:
		push_error("GODOT_SMOKE_FAIL=" + ",".join(failures))
		quit(1)
