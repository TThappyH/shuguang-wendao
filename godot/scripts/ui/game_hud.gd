class_name GameHUD
extends Control

var game: Node
var player: PlayerController
var swords: SwordManager
var director: EncounterDirector
var progression: RunProgression
var region_id := "ruins"
var debug_visible := false
var _font: Font
var _font_bold: Font
var _box_styles: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_font = ThemeDB.fallback_font
	_font_bold = ThemeDB.fallback_font

func configure(owner_game: Node, owner_player: PlayerController, owner_swords: SwordManager, owner_director: EncounterDirector, owner_progression: RunProgression) -> void:
	game = owner_game
	player = owner_player
	swords = owner_swords
	director = owner_director
	progression = owner_progression
	queue_redraw()

func set_region(next_region: String) -> void:
	region_id = next_region
	queue_redraw()

func set_debug_visible(value: bool) -> void:
	debug_visible = value
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(player) or not is_instance_valid(director) or not is_instance_valid(swords) or not is_instance_valid(progression):
		return
	var size := get_viewport_rect().size
	_draw_top_left()
	_draw_top_center(size)
	_draw_bottom_center(size)
	_draw_bottom_right(size)
	if debug_visible:
		_draw_debug_panel(size)
	if progression.draft_active:
		_draw_upgrade_draft(size)
	elif game.run_over:
		_draw_run_over(size)

func _draw_top_left() -> void:
	var panel := Rect2(24, 22, 310, 126)
	_draw_panel(panel, Color("102d31"), Color("71d4c1"))
	draw_string(_font_bold, panel.position + Vector2(18, 25), "青曜 · QINGYAO", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("edf0d3"))
	draw_string(_font, panel.position + Vector2(18, 46), "人走位，剑作战", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("a9ccc1"))
	var hp_ratio := clampf(player.hp / player.max_hp, 0.0, 1.0)
	draw_string(_font, panel.position + Vector2(18, 69), "气血", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("b5d6c9"))
	draw_rect(Rect2(panel.position + Vector2(55, 59), Vector2(216, 10)), Color("1e4848"), true)
	draw_rect(Rect2(panel.position + Vector2(55, 59), Vector2(216 * hp_ratio, 10)), Color("e28b72"), true)
	draw_string(_font_bold, panel.position + Vector2(278, 69), "%d/%d" % [maxi(0, roundi(player.hp)), roundi(player.max_hp)], HORIZONTAL_ALIGNMENT_RIGHT, 52, 10, Color("f0d9ba"))
	var essence_ratio := float(progression.essence) / float(maxi(1, progression.next_level_essence))
	draw_string(_font, panel.position + Vector2(18, 92), "道行 %02d" % progression.level, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("b5d6c9"))
	draw_rect(Rect2(panel.position + Vector2(76, 82), Vector2(195, 8)), Color("1c4043"), true)
	draw_rect(Rect2(panel.position + Vector2(76, 82), Vector2(195 * essence_ratio, 8)), Color("65d6bf"), true)
	draw_string(_font, panel.position + Vector2(18, 115), "敌影 %02d    击破 %02d    阶段 %s" % [director.enemies.size(), director.kills, String(director.current_phase)], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("d1e5d6"))

func _draw_top_center(size: Vector2) -> void:
	var region: Dictionary = WorldConfig.REGIONS.get(region_id, WorldConfig.REGIONS.ruins)
	var center := Vector2(size.x * 0.5, 26)
	draw_string(_font_bold, center + Vector2(-100, 21), "%s  ·  %s" % [region.short, region.name], HORIZONTAL_ALIGNMENT_CENTER, 200, 17, Color("f4e6c8"))
	draw_string(_font, center + Vector2(-120, 40), "ENCOUNTER  %s  /  PRESSURE %02d%%" % [String(director.current_phase), roundi(director.phase_intensity * 100.0)], HORIZONTAL_ALIGNMENT_CENTER, 240, 9, Color("d4e7dc"))
	draw_line(center + Vector2(-82, 52), center + Vector2(82, 52), region.accent, 1.0)

func _draw_bottom_center(size: Vector2) -> void:
	var origin := Vector2(size.x * 0.5 - 104, size.y - 88)
	for index in 3:
		var rect := Rect2(origin + Vector2(index * 72, 0), Vector2(60, 60))
		_draw_panel(rect, Color("102d31", 0.9), Color("7ed6c8", 0.7))
		var state_text := "FORMATION"
		if index < swords.swords.size():
			state_text = FlyingSword.SwordState.keys()[swords.swords[index].state]
		draw_string(_font_bold, rect.position + Vector2(30, 25), "剑 %d" % (index + 1), HORIZONTAL_ALIGNMENT_CENTER, 0, 12, Color("f4e6c8"))
		draw_string(_font, rect.position + Vector2(30, 44), state_text, HORIZONTAL_ALIGNMENT_CENTER, 0, 7, Color("9dd7c7"))
	var stats := "出剑 %03d  ·  命中 %03d  ·  连穿 %02d  ·  均值 %.2f" % [swords.shots_fired, swords.hits, swords.multi_hit_shots, swords.average_hits_per_shot()]
	draw_string(_font, Vector2(size.x * 0.5 - 190, size.y - 17), stats, HORIZONTAL_ALIGNMENT_CENTER, 380, 10, Color("dce8d8"))

func _draw_bottom_right(size: Vector2) -> void:
	var hint := Rect2(size.x - 326, size.y - 72, 302, 48)
	_draw_panel(hint, Color("102d31", 0.78), Color("b9d8c8", 0.38))
	draw_string(_font, hint.position + Vector2(14, 19), "WASD 移动   SPACE 闪身   R 重启", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e8ecd4"))
	draw_string(_font, hint.position + Vector2(14, 37), "1 / 3 / 8 敌群压力   F3 数据面板", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("a7cabe"))

func _draw_debug_panel(size: Vector2) -> void:
	var panel := Rect2(size.x - 320, 22, 296, 222)
	_draw_panel(panel, Color("0c2226", 0.96), Color("e3c57d", 0.8))
	var lines := [
		"DEBUG / V10 CORE OBSERVABILITY",
		"Phase / Target    %s / %02d" % [String(director.current_phase), director.snapshot().target_count],
		"Enemy / Peak      %02d / %02d" % [director.enemies.size(), director.peak_enemies],
		"Spawned / Kills   %03d / %03d" % [director.total_spawned, director.kills],
		"Player HP         %03d / %03d" % [maxi(0, roundi(player.hp)), roundi(player.max_hp)],
		"Shots / Hits      %03d / %03d" % [swords.shots_fired, swords.hits],
		"Avg Hits / Shot   %.2f" % swords.average_hits_per_shot(),
		"Multi-Hit Rate    %.1f%%" % (swords.multi_hit_rate() * 100.0),
		"Distance Travel   %.1f m" % player.total_distance,
		"Damage Taken      %.0f" % director.damage_taken_total,
		"Feedback Pool     %02d / fixed" % game.feedback._pool.size()
	]
	for index in lines.size():
		draw_string(_font if index > 0 else _font_bold, panel.position + Vector2(14, 21 + index * 18), lines[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 10 if index > 0 else 11, Color("c9e0d3") if index > 0 else Color("efd6a0"))

func _draw_upgrade_draft(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.06, 0.07, 0.76), true)
	var width := minf(920.0, size.x - 80.0)
	var card_width := (width - 48.0) / 3.0
	var start := Vector2((size.x - width) * 0.5, size.y * 0.5 - 128.0)
	draw_string(_font_bold, Vector2(start.x, start.y - 42), "道途抉择 · 选择一项强化", HORIZONTAL_ALIGNMENT_CENTER, width, 24, Color("f5e4bb"))
	for index in progression.current_options.size():
		var option := progression.current_options[index]
		var rect := Rect2(start + Vector2(index * (card_width + 24.0), 0), Vector2(card_width, 228))
		_draw_panel(rect, Color("102d31", 0.98), option.accent)
		draw_string(_font_bold, rect.position + Vector2(18, 36), "%d" % (index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, option.accent)
		draw_string(_font_bold, rect.position + Vector2(18, 78), option.title, HORIZONTAL_ALIGNMENT_CENTER, card_width - 36, 21, Color("f3e8cb"))
		draw_string(_font, rect.position + Vector2(18, 122), option.description, HORIZONTAL_ALIGNMENT_CENTER, card_width - 36, 13, Color("c9ddd2"))
		var stack := int(progression.stacks.get(option.id, 0))
		draw_string(_font, rect.position + Vector2(18, 190), "当前 %d / %d" % [stack, option.max_stacks], HORIZONTAL_ALIGNMENT_CENTER, card_width - 36, 10, Color("94bdb2"))
	draw_string(_font, Vector2(start.x, start.y + 260), "按 1 / 2 / 3 选择", HORIZONTAL_ALIGNMENT_CENTER, width, 12, Color("b9d7ca"))

func _draw_run_over(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.04, 0.05, 0.72), true)
	var panel := Rect2(size * 0.5 - Vector2(210, 82), Vector2(420, 164))
	_draw_panel(panel, Color("151f22", 0.98), Color("d28268"))
	draw_string(_font_bold, panel.position + Vector2(20, 55), "问道暂止", HORIZONTAL_ALIGNMENT_CENTER, 380, 28, Color("f0d6b5"))
	draw_string(_font, panel.position + Vector2(20, 92), "道行 %d · 击破 %d · 行进 %.1f m" % [progression.level, director.kills, player.total_distance], HORIZONTAL_ALIGNMENT_CENTER, 380, 12, Color("c5d9cf"))
	draw_string(_font_bold, panel.position + Vector2(20, 132), "按 R 重新入阵", HORIZONTAL_ALIGNMENT_CENTER, 380, 15, Color("72d9c5"))

func _draw_panel(rect: Rect2, fill: Color, line: Color) -> void:
	var key := fill.to_html(true) + ":" + line.to_html(true)
	if not _box_styles.has(key):
		var box := StyleBoxFlat.new()
		box.bg_color = fill
		box.border_color = line
		box.set_border_width_all(1)
		box.set_corner_radius_all(5)
		_box_styles[key] = box
	draw_style_box(_box_styles[key], rect)
