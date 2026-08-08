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
	if snapshot.get("enemy_count", 0) < 1:
		failures.append("enemy_spawn")
	if not main.player._visual.loaded:
		failures.append("qingyao_glb")
	if main.level._blockers.size() < 20:
		failures.append("map_blockers")
	if failures.is_empty():
		print("GODOT_SMOKE_PASS")
		quit(0)
	else:
		push_error("GODOT_SMOKE_FAIL=" + ",".join(failures))
		quit(1)

