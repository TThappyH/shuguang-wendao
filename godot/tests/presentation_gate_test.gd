extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("PRESENTATION_GATE_FAIL=main_scene")
		quit(1)
		return
	var main := packed.instantiate()
	root.add_child(main)
	current_scene = main
	await create_timer(2.6).timeout
	var failures: Array[String] = []
	var snapshot: Dictionary = main.debug_snapshot()
	var camera: Dictionary = snapshot.get("camera", {})
	var pitch := float(camera.get("pitch_degrees", 0.0))
	if pitch < 55.0 or pitch > 60.0:
		failures.append("camera_pitch_%.2f" % pitch)
	var hud: Dictionary = snapshot.get("hud", {})
	if not hud.get("structured_controls", false) or int(hud.get("sword_cards", 0)) != 3:
		failures.append("structured_hud")
	if int(hud.get("minimum_combat_font_size", 0)) < 12:
		failures.append("hud_readability")
	var world: Dictionary = snapshot.get("world", {})
	if world.get("navigation_profile", "") != "FIVE_REGION_GRAPH":
		failures.append("navigation_profile")
	if int(world.get("gameplay_collision_proxies", 0)) < WorldConfig.BLOCKERS.size():
		failures.append("collision_proxies")
	if main.level.can_stand(Vector3(-7.0, 0.08, -7.0), 0.42):
		failures.append("blocker_semantics")
	if not main.level.can_stand(Vector3(13.0, 0.08, 0.0), 0.42):
		failures.append("gate_semantics")
	var fallback := QingyaoVisual.resolve_model_scene("res://assets/does-not-exist.glb", QingyaoVisual.MODEL_FALLBACK_PATH)
	if fallback.scene == null or fallback.path != QingyaoVisual.MODEL_FALLBACK_PATH:
		failures.append("qingyao_fallback")
	Input.action_press("move_right")
	await create_timer(0.22).timeout
	var moving: Dictionary = main.player.presentation_snapshot()
	Input.action_release("move_right")
	if moving.get("state", "") != "MOVE":
		failures.append("motion_state_move")
	Input.action_press("move_right")
	Input.action_press("dash")
	await process_frame
	Input.action_release("dash")
	await create_timer(0.05).timeout
	var dashing: Dictionary = main.player.presentation_snapshot()
	Input.action_release("move_right")
	if dashing.get("state", "") != "DASH":
		failures.append("motion_state_dash")
	for sword: FlyingSword in main.sword_manager.swords:
		if sword.get_node_or_null("SwordTrail") == null:
			failures.append("sword_trail_%d" % sword.formation_index)
	print("PRESENTATION_GATE_SNAPSHOT=" + JSON.stringify({"camera": camera, "hud": hud, "world": world, "moving": moving, "dashing": dashing}))
	if failures.is_empty():
		print("PRESENTATION_GATE_PASS")
		quit(0)
	else:
		push_error("PRESENTATION_GATE_FAIL=" + ",".join(failures))
		quit(1)
