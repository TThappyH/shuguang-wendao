extends SceneTree

const OUTPUT_PATH := "res://../evidence/v10.3_html_to_godot/01_breakthrough_runtime.png"

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await create_timer(1.0).timeout
	var main := current_scene
	var boss: EnemyController = main.realm_progression.force_boss_gate(0)
	boss.take_damage(boss.max_hp + 1.0)
	await create_timer(0.45, true, false, true).timeout
	if not main.realm_progression.breakthrough_active:
		push_error("BREAKTHROUGH_CAPTURE_GATE_NOT_OPEN")
		quit(1)
		return
	var image := root.get_texture().get_image()
	var absolute_path := ProjectSettings.globalize_path(OUTPUT_PATH)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var error := image.save_png(absolute_path)
	if error != OK:
		push_error("BREAKTHROUGH_CAPTURE_SAVE_FAILED=%d" % error)
		quit(1)
		return
	print("BREAKTHROUGH_CAPTURE_PASS=" + absolute_path)
	quit(0)
