extends SceneTree

const OUTPUT_PATH := "res://../evidence/v10.1_visual_asset_integration/05_godot_gameplay_60deg.png"

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await create_timer(3.0).timeout
	var main := current_scene
	if main == null:
		push_error("VISUAL_CAPTURE_NO_MAIN_SCENE")
		quit(1)
		return
	main.camera_rig.follow_height = 18.0
	main.camera_rig.follow_distance = 10.5
	main.camera_rig.reset_runtime()
	main.sword_manager.reset_runtime()
	for enemy: Node in get_nodes_in_group("enemies"):
		if enemy is Node3D:
			(enemy as Node3D).visible = false
	for sword: FlyingSword in main.sword_manager.swords:
		sword.set_physics_process(false)
		sword.reset_runtime()
	main.player.set_physics_process(false)
	await process_frame
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	var absolute_path := ProjectSettings.globalize_path(OUTPUT_PATH)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var error := image.save_png(absolute_path)
	if error != OK:
		push_error("VISUAL_CAPTURE_SAVE_FAILED=%d" % error)
		quit(1)
		return
	print("VISUAL_CAPTURE_PASS=" + absolute_path)
	quit(0)
