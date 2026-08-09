extends SceneTree

const OUTPUT_PATH := "res://../evidence/v10.2_code_presentation/01_runtime_gameplay_default.png"

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
	# Capture the shipped camera and live combat state. Do not freeze actors, hide
	# enemies, or override camera values: this image is gameplay evidence, not an
	# isolated asset beauty shot.
	main.director.set_debug_count(3)
	await create_timer(1.2).timeout
	var image := root.get_texture().get_image()
	var absolute_path := ProjectSettings.globalize_path(OUTPUT_PATH)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var error := image.save_png(absolute_path)
	if error != OK:
		push_error("VISUAL_CAPTURE_SAVE_FAILED=%d" % error)
		quit(1)
		return
	print("RUNTIME_VISUAL_CAPTURE_PASS=" + absolute_path)
	quit(0)
