class_name GameHUD
extends Control

var game: Node
var player: PlayerController
var swords: SwordManager
var director: EncounterDirector
var region_id := "ruins"
var debug_visible := false
var _font: Font
var _font_bold: Font

func _ready() -> void:
	set_process(true)
	_font = ThemeDB.fallback_font
	_font_bold = ThemeDB.fallback_font

func configure(owner_game: Node, owner_player: PlayerController, owner_swords: SwordManager, owner_director: EncounterDirector) -> void:
	game = owner_game
	player = owner_player
	swords = owner_swords
	director = owner_director
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
	if not is_instance_valid(player) or not is_instance_valid(director) or not is_instance_valid(swords):
		return
	var size := get_viewport_rect().size
	_draw_top_left()
	_draw_top_center(size)
	_draw_bottom_center(size)
	_draw_bottom_right(size)
	if debug_visible:
		_draw_debug_panel(size)

func _draw_top_left() -> void:
	var panel := Rect2(24, 22, 290, 104)
	_draw_panel(panel, Color("102d31"), Color("71d4c1"))
	draw_string(_font_bold, panel.position + Vector2(18, 25), "青曜 · QINGYAO", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("edf0d3"))
	draw_string(_font, panel.position + Vector2(18, 46), "问道五域 / PLAYABLE 3D SLICE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("a9ccc1"))
	var hp_ratio := clampf(player.hp / player.max_hp, 0.0, 1.0)
	draw_string(_font, panel.position + Vector2(18, 68), "气血", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("b5d6c9"))
	draw_rect(Rect2(panel.position + Vector2(55, 58), Vector2(198, 10)), Color("1e4848"), true)
	draw_rect(Rect2(panel.position + Vector2(55, 58), Vector2(198 * hp_ratio, 10)), Color("e28b72"), true)
	draw_string(_font_bold, panel.position + Vector2(262, 68), "%d" % maxi(0, roundi(player.hp)), HORIZONTAL_ALIGNMENT_RIGHT, 28, 11, Color("f0d9ba"))
	draw_string(_font, panel.position + Vector2(18, 91), "敌影 %02d    击杀 %02d" % [director.enemies.size(), director.kills], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("d1e5d6"))

func _draw_top_center(size: Vector2) -> void:
	var region: Dictionary = WorldConfig.REGIONS.get(region_id, WorldConfig.REGIONS.ruins)
	var center := Vector2(size.x * 0.5, 26)
	draw_string(_font_bold, center + Vector2(-80, 21), "%s  ·  %s" % [region.short, region.name], HORIZONTAL_ALIGNMENT_CENTER, 160, 17, Color("f4e6c8"))
	draw_string(_font, center + Vector2(-110, 40), "FIVE REALM EXPEDITION  /  %s" % region_id.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 220, 9, Color("d4e7dc"))
	draw_line(center + Vector2(-70, 52), center + Vector2(70, 52), region.accent, 1.0)

func _draw_bottom_center(size: Vector2) -> void:
	var origin := Vector2(size.x * 0.5 - 104, size.y - 88)
	for index in 3:
		var rect := Rect2(origin + Vector2(index * 72, 0), Vector2(60, 60))
		_draw_panel(rect, Color("102d31", 0.9), Color("7ed6c8", 0.7))
		var state_text: String = "FORMATION"
		if index < swords.swords.size():
			state_text = FlyingSword.SwordState.keys()[swords.swords[index].state]
		draw_string(_font_bold, rect.position + Vector2(30, 25), "剑 %d" % (index + 1), HORIZONTAL_ALIGNMENT_CENTER, 0, 12, Color("f4e6c8"))
		draw_string(_font, rect.position + Vector2(30, 44), state_text, HORIZONTAL_ALIGNMENT_CENTER, 0, 7, Color("9dd7c7"))
	var stats := "出剑 %03d  ·  命中 %03d  ·  穿透 %02d" % [swords.shots_fired, swords.hits, swords.multi_hit_shots]
	draw_string(_font, Vector2(size.x * 0.5 - 150, size.y - 17), stats, HORIZONTAL_ALIGNMENT_CENTER, 300, 10, Color("dce8d8"))

func _draw_bottom_right(size: Vector2) -> void:
	var hint := Rect2(size.x - 316, size.y - 72, 292, 48)
	_draw_panel(hint, Color("102d31", 0.78), Color("b9d8c8", 0.38))
	draw_string(_font, hint.position + Vector2(14, 19), "WASD 移动   SPACE 闪身   R 重启", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e8ecd4"))
	draw_string(_font, hint.position + Vector2(14, 37), "1 / 3 / 8 调试敌群   F3 数据面板", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("a7cabe"))

func _draw_debug_panel(size: Vector2) -> void:
	var panel := Rect2(size.x - 300, 22, 276, 170)
	_draw_panel(panel, Color("0c2226", 0.96), Color("e3c57d", 0.8))
	var lines := [
		"DEBUG / RUNTIME OBSERVABILITY",
		"Enemy Count       %02d" % director.enemies.size(),
		"Player HP         %03d / 120" % maxi(0, roundi(player.hp)),
		"Shots / Hits      %03d / %03d" % [swords.shots_fired, swords.hits],
		"Avg Hits / Shot   %.2f" % swords.average_hits_per_shot(),
		"Multi-Hit Rate    %.1f%%" % (swords.multi_hit_rate() * 100.0),
		"Distance Travel   %.1f m" % player.total_distance,
		"Damage Taken      %.0f" % director.damage_taken_total
	]
	for index in lines.size():
		draw_string(_font if index > 0 else _font_bold, panel.position + Vector2(14, 21 + index * 18), lines[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 10 if index > 0 else 11, Color("c9e0d3") if index > 0 else Color("efd6a0"))

func _draw_panel(rect: Rect2, fill: Color, line: Color) -> void:
	draw_style_box(_box_style(fill, line), rect)

func _box_style(fill: Color, line: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = line
	box.set_border_width_all(1)
	box.corner_radius_top_left = 5
	box.corner_radius_top_right = 5
	box.corner_radius_bottom_left = 5
	box.corner_radius_bottom_right = 5
	return box
