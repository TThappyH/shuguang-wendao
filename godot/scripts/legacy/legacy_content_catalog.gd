class_name LegacyContentCatalog
extends RefCounted

const CONTENT_PATH := "res://data/legacy/v67_content.json"

static var _payload: Dictionary = {}

static func load_catalog() -> Dictionary:
	if not _payload.is_empty():
		return _payload
	if not FileAccess.file_exists(CONTENT_PATH):
		push_error("Legacy HTML content catalog missing: %s" % CONTENT_PATH)
		return {}
	var file := FileAccess.open(CONTENT_PATH, FileAccess.READ)
	if file == null:
		push_error("Legacy HTML content catalog could not be opened")
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Legacy HTML content catalog is invalid JSON")
		return {}
	_payload = parsed as Dictionary
	return _payload

static func content() -> Dictionary:
	return load_catalog().get("content", {}) as Dictionary

static func counts() -> Dictionary:
	return load_catalog().get("counts", {}) as Dictionary

static func list(section: StringName) -> Array:
	var value = content().get(String(section), [])
	return value as Array if value is Array else []

static func table(section: StringName) -> Dictionary:
	var value = content().get(String(section), {})
	return value as Dictionary if value is Dictionary else {}

static func realm(index: int) -> Dictionary:
	var realms := list(&"realms")
	return realms[index] as Dictionary if index >= 0 and index < realms.size() else {}

static func rule(rule_id: StringName) -> Dictionary:
	return table(&"rules").get(String(rule_id), {}) as Dictionary

static func boss(index: int) -> Dictionary:
	var bosses := list(&"bosses")
	return bosses[index] as Dictionary if index >= 0 and index < bosses.size() else {}

static func validate() -> Array[String]:
	var failures: Array[String] = []
	var expected := {
		"realms": 6, "rules": 15, "weapons": 9, "passives": 12,
		"relics": 24, "resonance_paths": 6, "regions": 5,
		"encounter_templates": 4, "enemies": 9, "bosses": 6
	}
	for key: String in expected:
		if int(counts().get(key, -1)) != int(expected[key]):
			failures.append("count_%s" % key)
	if list(&"boss_schedule_seconds").size() != 6:
		failures.append("boss_schedule")
	return failures

static func snapshot() -> Dictionary:
	var payload := load_catalog()
	return {
		"schema_version": int(payload.get("schema_version", 0)),
		"source": String(payload.get("source", "")),
		"source_sha256": String(payload.get("source_sha256", "")),
		"counts": counts().duplicate(true),
		"valid": validate().is_empty()
	}
