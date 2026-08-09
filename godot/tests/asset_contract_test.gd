extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array[String] = []
	var warnings: Array[String] = []
	var slots := RodinAssetRegistry.audit_slots()
	var geometry_reports: Array[Dictionary] = []
	for audit: Dictionary in slots:
		if audit.required and not audit.exists:
			failures.append("missing_required_%s" % audit.slot)
		if audit.prototype_exempt:
			warnings.append("prototype_budget_exempt_%s" % audit.slot)
		if audit.exists:
			var report := RodinAssetRegistry.geometry_report(StringName(audit.slot))
			geometry_reports.append(report)
			if report.over_triangle_hard_max:
				warnings.append("triangle_hard_max_%s_%d" % [audit.slot, report.triangles])
				if not report.prototype_exempt:
					failures.append("triangle_budget_%s" % audit.slot)
			if report.over_material_max and not report.prototype_exempt:
				failures.append("material_budget_%s" % audit.slot)
	var manifest := RodinAssetRegistry.manifest()
	if manifest.get("api_used", true):
		failures.append("rodin_api_must_remain_disabled")
	if String(manifest.get("pipeline", "")).find("RodinBridge") < 0:
		failures.append("rodin_bridge_pipeline")
	print("RODIN_ASSET_CONTRACT=" + JSON.stringify({"slots": slots, "geometry": geometry_reports, "warnings": warnings}))
	if failures.is_empty():
		print("ASSET_CONTRACT_TEST_PASS")
		quit(0)
	else:
		push_error("ASSET_CONTRACT_TEST_FAIL=" + ",".join(failures))
		quit(1)
