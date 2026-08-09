extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures := LegacyContentCatalog.validate()
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		failures.append("main_scene")
		_finish(failures, {})
		return
	var main := packed.instantiate()
	root.add_child(main)
	current_scene = main
	await create_timer(0.8).timeout
	var boss: EnemyController = main.realm_progression.force_boss_gate(0)
	if not is_instance_valid(boss) or not boss.is_boss or boss.boss_index != 0:
		failures.append("boss_spawn")
	else:
		boss.take_damage(boss.max_hp + 1.0)
	await create_timer(0.35, true, false, true).timeout
	if not main.realm_progression.breakthrough_active:
		failures.append("breakthrough_not_open")
	if main.realm_progression.pending_options.size() != 3:
		failures.append("breakthrough_options")
	var chosen: bool = main.realm_progression.choose_breakthrough(0)
	if not chosen or main.realm_progression.current_realm_index != 1:
		failures.append("realm_choice")
	var snapshot: Dictionary = main.debug_snapshot()
	var legacy: Dictionary = snapshot.get("legacy_html_content", {})
	if not legacy.get("valid", false):
		failures.append("catalog_snapshot")
	_finish(failures, snapshot)

func _finish(failures: Array[String], snapshot: Dictionary) -> void:
	print("LEGACY_HTML_CONVERSION_SNAPSHOT=" + JSON.stringify({
		"catalog": snapshot.get("legacy_html_content", LegacyContentCatalog.snapshot()),
		"realm": snapshot.get("realm_progression", {}),
		"bosses": LegacyContentCatalog.counts().get("bosses", 0)
	}))
	if failures.is_empty():
		print("LEGACY_HTML_CONVERSION_PASS")
		quit(0)
	else:
		push_error("LEGACY_HTML_CONVERSION_FAIL=" + ",".join(failures))
		quit(1)
