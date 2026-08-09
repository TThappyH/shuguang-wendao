class_name GameHUD
extends Control

const INK := Color("07191d")
const PANEL := Color("0b2529", 0.94)
const PANEL_SOFT := Color("12373a", 0.88)
const JADE := Color("62d5c1")
const JADE_PALE := Color("b8e5d9")
const IVORY := Color("f3ead2")
const MUTED := Color("91b8ad")
const GOLD := Color("dfc27b")
const HP := Color("e07f69")
const DANGER := Color("d9675d")

var game: Node
var player: PlayerController
var swords: SwordManager
var director: EncounterDirector
var progression: RunProgression
var region_id := "ruins"
var debug_visible := false

var _health_panel: PanelContainer
var _hp_bar: ProgressBar
var _hp_value: Label
var _essence_bar: ProgressBar
var _level_value: Label
var _encounter_value: Label
var _region_panel: PanelContainer
var _region_title: Label
var _phase_value: Label
var _pressure_bar: ProgressBar
var _sword_states: Array[Label] = []
var _sword_cards: Array[PanelContainer] = []
var _combat_stats: Label
var _dash_bar: ProgressBar
var _dash_value: Label
var _debug_panel: PanelContainer
var _debug_text: Label
var _draft_overlay: ColorRect
var _draft_cards: HBoxContainer
var _run_over_overlay: ColorRect
var _run_summary: Label
var _refresh_clock := 0.0
var _hp_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_theme()
	_build_hud()

func configure(owner_game: Node, owner_player: PlayerController, owner_swords: SwordManager, owner_director: EncounterDirector, owner_progression: RunProgression) -> void:
	game = owner_game
	player = owner_player
	swords = owner_swords
	director = owner_director
	progression = owner_progression
	player.health_changed.connect(_on_health_changed)
	player.dash_ready_changed.connect(_on_dash_ready_changed)
	swords.metrics_changed.connect(_on_metrics_changed)
	swords.sword_state_changed.connect(_on_sword_state_changed)
	director.enemy_count_changed.connect(_on_enemy_count_changed)
	director.phase_changed.connect(_on_phase_changed)
	progression.progression_changed.connect(_on_progression_changed)
	progression.draft_opened.connect(_on_draft_opened)
	progression.draft_closed.connect(_on_draft_closed)
	refresh()

func set_region(next_region: String) -> void:
	region_id = next_region
	_refresh_region()
	if is_instance_valid(_region_panel):
		_region_panel.modulate = Color(1.35, 1.35, 1.35, 0.35)
		var tween := create_tween()
		tween.tween_property(_region_panel, "modulate", Color.WHITE, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func set_debug_visible(value: bool) -> void:
	debug_visible = value
	if is_instance_valid(_debug_panel):
		_debug_panel.visible = value
	refresh()

func refresh() -> void:
	if not _runtime_valid():
		return
	_refresh_health(false)
	_refresh_progression()
	_refresh_encounter()
	_refresh_region()
	_refresh_swords()
	_refresh_dash()
	_refresh_overlays()
	_refresh_debug()

func snapshot() -> Dictionary:
	return {
		"structured_controls": true,
		"health_panel": is_instance_valid(_health_panel),
		"region_panel": is_instance_valid(_region_panel),
		"sword_cards": _sword_cards.size(),
		"minimum_combat_font_size": 12,
		"event_driven": true,
		"debug_visible": debug_visible
	}

func _process(delta: float) -> void:
	if not _runtime_valid():
		return
	_refresh_clock += delta
	if _refresh_clock < 0.08:
		return
	_refresh_clock = 0.0
	_refresh_swords()
	_refresh_dash()
	_refresh_overlays()
	if debug_visible:
		_refresh_debug()

func _runtime_valid() -> bool:
	return is_instance_valid(game) and is_instance_valid(player) and is_instance_valid(swords) and is_instance_valid(director) and is_instance_valid(progression)

func _build_theme() -> void:
	var hud_theme := Theme.new()
	hud_theme.default_font = ThemeDB.fallback_font
	hud_theme.set_font_size("font_size", "Label", 14)
	hud_theme.set_color("font_color", "Label", IVORY)
	hud_theme.set_font_size("font_size", "Button", 15)
	hud_theme.set_color("font_color", "Button", IVORY)
	hud_theme.set_color("font_hover_color", "Button", Color.WHITE)
	hud_theme.set_color("font_focus_color", "Button", Color.WHITE)
	theme = hud_theme

func _build_hud() -> void:
	_build_health_panel()
	_build_region_panel()
	_build_sword_dock()
	_build_command_panel()
	_build_debug_panel()
	_build_draft_overlay()
	_build_run_over_overlay()

func _build_health_panel() -> void:
	_health_panel = _panel("VitalPanel", PANEL, JADE, 10)
	_health_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_health_panel.position = Vector2(24, 22)
	_health_panel.custom_minimum_size = Vector2(360, 154)
	add_child(_health_panel)
	var margin := _margin(18, 14, 18, 14)
	_health_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)
	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	var title := _label("青曜", 21, IVORY, true)
	title_row.add_child(title)
	var subtitle := _label("  QINGYAO  ·  剑阵行者", 12, MUTED)
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(subtitle)
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 10)
	column.add_child(hp_row)
	hp_row.add_child(_label("气血", 13, JADE_PALE, true))
	_hp_bar = _bar("HealthBar", HP, Color("183b3e"), Vector2(218, 12))
	_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(_hp_bar)
	_hp_value = _label("120 / 120", 13, IVORY, true)
	_hp_value.custom_minimum_size.x = 78
	_hp_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_row.add_child(_hp_value)
	var path_row := HBoxContainer.new()
	path_row.add_theme_constant_override("separation", 10)
	column.add_child(path_row)
	_level_value = _label("道行 01", 13, GOLD, true)
	_level_value.custom_minimum_size.x = 62
	path_row.add_child(_level_value)
	_essence_bar = _bar("EssenceBar", JADE, Color("183b3e"), Vector2(200, 9))
	_essence_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	path_row.add_child(_essence_bar)
	_encounter_value = _label("敌影 00  ·  击破 00", 13, JADE_PALE)
	column.add_child(_encounter_value)
	var motto := _label("人走位，剑作战", 12, MUTED)
	motto.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(motto)

func _build_region_panel() -> void:
	_region_panel = _panel("RegionPanel", Color("081f23", 0.9), GOLD, 10)
	_region_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_region_panel.position = Vector2(-190, 22)
	_region_panel.custom_minimum_size = Vector2(380, 92)
	add_child(_region_panel)
	var margin := _margin(18, 10, 18, 10)
	_region_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	margin.add_child(column)
	_region_title = _label("庭 · 晨曦遗庭", 19, IVORY, true)
	_region_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_region_title)
	_phase_value = _label("WARMUP  ·  敌势 16%", 12, JADE_PALE, true)
	_phase_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_phase_value)
	_pressure_bar = _bar("PressureBar", GOLD, Color("173337"), Vector2(340, 7))
	column.add_child(_pressure_bar)

func _build_sword_dock() -> void:
	var dock := _panel("SwordDock", Color("081f23", 0.92), JADE, 12)
	dock.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dock.position = Vector2(-228, -110)
	dock.custom_minimum_size = Vector2(456, 88)
	add_child(dock)
	var margin := _margin(12, 10, 12, 8)
	dock.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)
	for index in 3:
		var card := _panel("SwordCard%d" % (index + 1), PANEL_SOFT, Color(JADE, 0.55), 7)
		card.custom_minimum_size = Vector2(132, 48)
		row.add_child(card)
		_sword_cards.append(card)
		var card_margin := _margin(8, 5, 8, 5)
		card.add_child(card_margin)
		var card_row := HBoxContainer.new()
		card_row.add_theme_constant_override("separation", 8)
		card_margin.add_child(card_row)
		var number := _label("%d" % (index + 1), 20, GOLD, true)
		number.custom_minimum_size.x = 22
		card_row.add_child(number)
		var state_label := _label("归阵\nFORMATION", 12, JADE_PALE, true)
		state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		state_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_row.add_child(state_label)
		_sword_states.append(state_label)
	_combat_stats = _label("出剑 000  ·  命中 000  ·  连穿 00  ·  均值 0.00", 12, MUTED)
	_combat_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_combat_stats)

func _build_command_panel() -> void:
	var command := _panel("CommandPanel", Color("081f23", 0.84), Color(JADE_PALE, 0.35), 9)
	command.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	command.position = Vector2(-348, -96)
	command.custom_minimum_size = Vector2(324, 74)
	add_child(command)
	var margin := _margin(14, 9, 14, 9)
	command.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	margin.add_child(column)
	var dash_row := HBoxContainer.new()
	dash_row.add_theme_constant_override("separation", 9)
	column.add_child(dash_row)
	_dash_value = _label("闪身 READY", 13, JADE, true)
	_dash_value.custom_minimum_size.x = 84
	dash_row.add_child(_dash_value)
	_dash_bar = _bar("DashBar", JADE, Color("18383b"), Vector2(190, 8))
	_dash_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dash_row.add_child(_dash_bar)
	column.add_child(_label("WASD 移动   SPACE 闪身   R 重启", 12, IVORY))
	column.add_child(_label("1 / 3 / 8 敌群压力   F3 观测面板", 11, MUTED))

func _build_debug_panel() -> void:
	_debug_panel = _panel("DebugPanel", Color("07191d", 0.97), GOLD, 9)
	_debug_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_debug_panel.position = Vector2(-334, 22)
	_debug_panel.custom_minimum_size = Vector2(310, 250)
	_debug_panel.visible = false
	add_child(_debug_panel)
	var margin := _margin(14, 12, 14, 12)
	_debug_panel.add_child(margin)
	_debug_text = _label("", 11, JADE_PALE)
	_debug_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(_debug_text)

func _build_draft_overlay() -> void:
	_draft_overlay = ColorRect.new()
	_draft_overlay.name = "UpgradeDraftOverlay"
	_draft_overlay.color = Color(0.015, 0.055, 0.065, 0.9)
	_draft_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_draft_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_draft_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_draft_overlay.visible = false
	add_child(_draft_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_draft_overlay.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(1040, 390)
	column.add_theme_constant_override("separation", 18)
	center.add_child(column)
	var heading := _label("道途抉择", 32, IVORY, true)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	var subheading := _label("择一法门，重塑此局剑势", 14, MUTED)
	subheading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(subheading)
	_draft_cards = HBoxContainer.new()
	_draft_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	_draft_cards.add_theme_constant_override("separation", 18)
	column.add_child(_draft_cards)

func _build_run_over_overlay() -> void:
	_run_over_overlay = ColorRect.new()
	_run_over_overlay.name = "RunOverOverlay"
	_run_over_overlay.color = Color(0.02, 0.035, 0.04, 0.84)
	_run_over_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_run_over_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_run_over_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_run_over_overlay.visible = false
	add_child(_run_over_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_run_over_overlay.add_child(center)
	var panel := _panel("RunSummaryPanel", Color("101e22", 0.98), DANGER, 14)
	panel.custom_minimum_size = Vector2(520, 230)
	center.add_child(panel)
	var margin := _margin(24, 24, 24, 24)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	var title := _label("问道暂止", 32, IVORY, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	_run_summary = _label("", 14, JADE_PALE)
	_run_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_run_summary)
	var restart := _label("按 R 重新入阵", 17, JADE, true)
	restart.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(restart)

func _refresh_health(animated := true) -> void:
	var ratio := clampf(player.hp / maxf(player.max_hp, 1.0), 0.0, 1.0)
	var target := ratio * 100.0
	if animated:
		if _hp_tween != null and _hp_tween.is_valid():
			_hp_tween.kill()
		_hp_tween = create_tween()
		_hp_tween.tween_property(_hp_bar, "value", target, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		_hp_bar.value = target
	_hp_value.text = "%d / %d" % [maxi(0, roundi(player.hp)), roundi(player.max_hp)]
	_hp_bar.modulate = Color.WHITE if ratio > 0.3 else Color(1.2, 0.72, 0.72)

func _refresh_progression() -> void:
	_level_value.text = "道行 %02d" % progression.level
	_essence_bar.value = float(progression.essence) / float(maxi(1, progression.next_level_essence)) * 100.0

func _refresh_encounter() -> void:
	_encounter_value.text = "敌影 %02d  ·  击破 %02d" % [director.enemies.size(), director.kills]

func _refresh_region() -> void:
	if not is_instance_valid(_region_title) or not is_instance_valid(director):
		return
	var region: Dictionary = WorldConfig.REGIONS.get(region_id, WorldConfig.REGIONS.ruins)
	_region_title.text = "%s  ·  %s" % [region.short, region.name]
	_phase_value.text = "%s  ·  敌势 %02d%%" % [String(director.current_phase), roundi(director.phase_intensity * 100.0)]
	_pressure_bar.value = director.phase_intensity * 100.0

func _refresh_swords() -> void:
	for index in _sword_states.size():
		var state_name := "FORMATION"
		if index < swords.swords.size():
			state_name = FlyingSword.SwordState.keys()[swords.swords[index].state]
		_sword_states[index].text = "%s\n%s" % [_state_cn(state_name), state_name]
		var active := state_name in ["ANTICIPATE", "LAUNCH", "TRAVEL", "IMPACT"]
		_sword_cards[index].modulate = Color(1.12, 1.12, 1.12) if active else Color.WHITE
	_combat_stats.text = "出剑 %03d  ·  命中 %03d  ·  连穿 %02d  ·  均值 %.2f" % [swords.shots_fired, swords.hits, swords.multi_hit_shots, swords.average_hits_per_shot()]

func _refresh_dash() -> void:
	_dash_bar.value = player.dash_ratio() * 100.0
	var ready := player.dash_ratio() >= 0.999
	_dash_value.text = "闪身 READY" if ready else "闪身蓄势"
	_dash_value.add_theme_color_override("font_color", JADE if ready else MUTED)

func _refresh_overlays() -> void:
	var draft := progression.draft_active
	_draft_overlay.visible = draft
	_run_over_overlay.visible = game.run_over and not draft
	if _run_over_overlay.visible:
		_run_summary.text = "道行 %d  ·  击破 %d  ·  行进 %.1f m\n平均命中 %.2f  ·  连穿率 %.1f%%" % [progression.level, director.kills, player.total_distance, swords.average_hits_per_shot(), swords.multi_hit_rate() * 100.0]

func _refresh_debug() -> void:
	if not debug_visible or not _runtime_valid():
		return
	var encounter := director.snapshot()
	var presentation := player.presentation_snapshot()
	_debug_text.text = "DEBUG / RUNTIME OBSERVABILITY\n\nPhase / Target     %s / %02d\nEnemy / Peak       %02d / %02d\nSpawned / Kills    %03d / %03d\nPlayer HP          %03d / %03d\nMotion State       %s\nShots / Hits       %03d / %03d\nAvg Hits / Shot    %.2f\nMulti-Hit Rate     %.1f%%\nDistance Travel    %.1f m\nDamage Taken       %.0f\nFeedback Pool      %02d / fixed" % [String(director.current_phase), encounter.target_count, director.enemies.size(), director.peak_enemies, director.total_spawned, director.kills, maxi(0, roundi(player.hp)), roundi(player.max_hp), presentation.get("state", "UNKNOWN"), swords.shots_fired, swords.hits, swords.average_hits_per_shot(), swords.multi_hit_rate() * 100.0, player.total_distance, director.damage_taken_total, game.feedback._pool.size()]

func _on_health_changed(_current: float, _maximum: float) -> void:
	_refresh_health(true)
	_health_panel.modulate = Color(1.25, 0.82, 0.82)
	var tween := create_tween()
	tween.tween_property(_health_panel, "modulate", Color.WHITE, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_dash_ready_changed(_ready: bool) -> void:
	_refresh_dash()

func _on_metrics_changed(_shots: int, _hits: int, _multi: int) -> void:
	_refresh_swords()

func _on_sword_state_changed(_index: int, _state_name: StringName) -> void:
	_refresh_swords()

func _on_enemy_count_changed(_count: int) -> void:
	_refresh_encounter()

func _on_phase_changed(_phase: StringName, _intensity: float, _target: int) -> void:
	_refresh_region()

func _on_progression_changed(_level: int, _essence: int, _next: int) -> void:
	_refresh_progression()

func _on_draft_opened(_options: Array[UpgradeDefinition]) -> void:
	_rebuild_draft_cards()
	_draft_overlay.visible = true

func _on_draft_closed() -> void:
	_draft_overlay.visible = false

func _rebuild_draft_cards() -> void:
	for child in _draft_cards.get_children():
		child.queue_free()
	for index in progression.current_options.size():
		var option := progression.current_options[index]
		var card := _panel("UpgradeCard%d" % (index + 1), PANEL, option.accent, 12)
		card.custom_minimum_size = Vector2(310, 250)
		_draft_cards.add_child(card)
		var margin := _margin(18, 18, 18, 18)
		card.add_child(margin)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 14)
		margin.add_child(column)
		var key := _label("0%d" % (index + 1), 18, option.accent, true)
		column.add_child(key)
		var title := _label(option.title, 23, IVORY, true)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(title)
		var description := _label(option.description, 14, JADE_PALE)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		description.custom_minimum_size.y = 72
		column.add_child(description)
		var stack := int(progression.stacks.get(option.id, 0))
		var stack_label := _label("当前层数  %d / %d" % [stack, option.max_stacks], 12, MUTED)
		stack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(stack_label)
		var choose := Button.new()
		choose.text = "选择此道"
		choose.custom_minimum_size = Vector2(0, 42)
		choose.focus_mode = Control.FOCUS_ALL
		choose.add_theme_stylebox_override("normal", _style(Color("174246"), option.accent, 7, 1))
		choose.add_theme_stylebox_override("hover", _style(Color("205b5d"), option.accent, 7, 2))
		choose.add_theme_stylebox_override("focus", _style(Color("205b5d"), Color.WHITE, 7, 2))
		choose.pressed.connect(_on_upgrade_pressed.bind(index))
		column.add_child(choose)
		if index == 0:
			choose.call_deferred("grab_focus")

func _on_upgrade_pressed(index: int) -> void:
	progression.choose(index)

func _state_cn(state_name: String) -> String:
	return {
		"FORMATION": "归阵",
		"ACQUIRE": "索敌",
		"ANTICIPATE": "蓄锋",
		"LAUNCH": "出鞘",
		"TRAVEL": "御剑",
		"IMPACT": "破敌",
		"RETURN": "回锋",
		"REFORM": "重整"
	}.get(state_name, "剑阵")

func _panel(node_name: String, fill: Color, border: Color, radius: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(fill, border, radius, 1))
	return panel

func _style(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.34)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	return style

func _margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin

func _label(text_value: String, size_value: int, color: Color, bold := false) -> Label:
	var label := Label.new()
	label.text = text_value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size_value)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_constant_override("outline_size", 1)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.42))
	return label

func _bar(node_name: String, fill: Color, background: Color, minimum: Vector2) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.name = node_name
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	bar.custom_minimum_size = minimum
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", _style(background, Color(background, 0.0), 4, 0))
	bar.add_theme_stylebox_override("fill", _style(fill, fill, 4, 0))
	return bar
