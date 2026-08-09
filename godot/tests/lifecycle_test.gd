extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	current_scene = main
	var failures: Array[String] = []
	for sword in main.sword_manager.swords:
		sword.set_physics_process(false)
	for target in [1, 3, 8]:
		main.director.set_debug_count(target)
		await create_timer(2.2).timeout
		if main.director.enemies.size() != target:
			failures.append("count_%d" % target)
		if main.director.enemies.size() > 8:
			failures.append("enemy_growth")
	main._reset_runtime()
	await create_timer(2.0).timeout
	var snapshot: Dictionary = main.debug_snapshot()
	if snapshot.encounter.enemy_count != 1:
		failures.append("reset_enemy_count")
	if snapshot.feedback_pool_size != 24:
		failures.append("pool_growth")
	print("LIFECYCLE_SHORT_SNAPSHOT=" + JSON.stringify(snapshot))
	if failures.is_empty():
		print("LIFECYCLE_SHORT_TEST_PASS")
		quit(0)
	else:
		push_error("LIFECYCLE_SHORT_TEST_FAIL=" + ",".join(failures))
		quit(1)
