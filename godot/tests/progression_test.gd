extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var main := packed.instantiate()
	root.add_child(main)
	current_scene = main
	await create_timer(1.0).timeout
	main.progression.grant_essence(4)
	await process_frame
	var failures: Array[String] = []
	if not main.progression.draft_active or main.progression.current_options.size() != 3:
		failures.append("three_choice_draft")
	var selected_id := ""
	if main.progression.current_options.size() == 3:
		selected_id = String(main.progression.current_options[0].id)
		if not main.progression.choose(0):
			failures.append("choose_upgrade")
	await process_frame
	if main.progression.level != 2 or main.progression.draft_active:
		failures.append("draft_close")
	if selected_id.is_empty() or int(main.progression.stacks.get(selected_id, 0)) != 1:
		failures.append("upgrade_stack")
	print("PROGRESSION_SNAPSHOT=" + JSON.stringify(main.progression.snapshot()))
	if failures.is_empty():
		print("PROGRESSION_TEST_PASS")
		quit(0)
	else:
		push_error("PROGRESSION_TEST_FAIL=" + ",".join(failures))
		quit(1)
