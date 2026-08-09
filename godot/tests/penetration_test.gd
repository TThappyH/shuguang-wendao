extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var player := Node3D.new()
	stage.add_child(player)
	var sword := FlyingSword.new()
	sword.configure(player, 0)
	stage.add_child(sword)
	sword.damage = 17.0
	sword.max_hits = 2
	sword.travel_direction = Vector3(0, 0, -1)
	var first := DamageDummy.new()
	first.position = Vector3(0, 0, -2)
	stage.add_child(first)
	var second := DamageDummy.new()
	second.position = Vector3(0, 0, -4)
	stage.add_child(second)
	sword._check_enemy_hits(Vector3(0, 0.7, 0), Vector3(0, 0.7, -2.6))
	sword._check_enemy_hits(Vector3(0, 0.7, -2.6), Vector3(0, 0.7, -4.6))
	var failures: Array[String] = []
	if first.hit_count != 1 or not is_equal_approx(first.hp, 83.0):
		failures.append("first_target_damage")
	if second.hit_count != 1 or not is_equal_approx(second.hp, 83.0):
		failures.append("second_target_damage")
	if sword.hit_targets.size() != 2:
		failures.append("max_two_targets")
	print("PENETRATION_SNAPSHOT=" + JSON.stringify({"first_hits": first.hit_count, "second_hits": second.hit_count, "registered": sword.hit_targets.size()}))
	if failures.is_empty():
		print("PENETRATION_TEST_PASS")
		quit(0)
	else:
		push_error("PENETRATION_TEST_FAIL=" + ",".join(failures))
		quit(1)
