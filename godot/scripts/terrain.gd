extends Node2D
class_name Terrain
## Platforms, pits, spikes, moving platforms and the level-end flag.
## Ported from drawPlatforms() in index.html.

var level_data: Dictionary = {}
var moving_platform_states: Array = []

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var theme: String = level_data.get("theme", "")

	for p in level_data.get("platforms", []):
		_draw_platform(p.x, p.y, p.w, p.h, Color(p.color), Color(p.top), theme)

	for mp in moving_platform_states:
		_draw_moving_platform(mp)

	for pit in level_data.get("pits", []):
		_draw_pit(pit)

	for sp in level_data.get("spikes", []):
		_draw_spike(sp)

	_draw_flag()

func _draw_platform(x: float, y: float, w: float, h: float, color: Color, top: Color, theme: String) -> void:
	var draw_h: float = min(h, 80.0)
	draw_rect(Rect2(x, y, w, draw_h), color)
	if h > draw_h:
		draw_rect(Rect2(x, y + draw_h, w, h - draw_h), color.darkened(0.22))
	draw_rect(Rect2(x, y, w, 8), top)
	draw_rect(Rect2(x + 0.5, y + 0.5, w - 1, min(h, 90) - 1), Color(0, 0, 0, 0), false, 1.0)
	draw_rect(Rect2(x + 0.5, y + 0.5, w - 1, min(h, 90) - 1), Color(0, 0, 0, 0.25), false, 1.0)

	if theme == "castle":
		var bx := 0.0
		while bx < w:
			draw_line(Vector2(x + bx, y + 8), Vector2(x + bx, y + min(h, 60)), Color(0, 0, 0, 0.18), 1.0)
			bx += 26
	elif theme == "forest":
		var gx := 4.0
		while gx < w:
			var pts := PackedVector2Array([Vector2(x + gx, y), Vector2(x + gx + 3, y - 7), Vector2(x + gx + 6, y)])
			draw_colored_polygon(pts, Color(1, 1, 1, 0.15))
			gx += 14
	else:
		var cx := 6.0
		while cx < w:
			draw_arc(Vector2(x + cx, y + 4), 4, PI, TAU, 12, Color(1, 1, 1, 0.08), 4.0)
			cx += 22

func _draw_moving_platform(mp: Dictionary) -> void:
	var color: Color = Color(mp.get("color", "#8a6a30"))
	draw_rect(Rect2(mp.x, mp.y, mp.w, mp.h), color)
	draw_rect(Rect2(mp.x, mp.y, mp.w, mp.h), color.darkened(0.25))
	draw_rect(Rect2(mp.x, mp.y, mp.w, 5), Color("#e8c766"))
	draw_rect(Rect2(mp.x + 0.5, mp.y + 0.5, mp.w - 1, mp.h - 1), Color(0, 0, 0, 0.35), false, 1.0)

func _draw_pit(pit: Dictionary) -> void:
	var ground_y: float = Game.GROUND_Y
	if pit.get("lava", false):
		draw_rect(Rect2(pit.x, ground_y, pit.w, 40), Color("#e0621c"))
		var bx := 0.0
		while bx < pit.w:
			var t := Time.get_ticks_msec() / 1000.0
			var yy: float = ground_y + 6 + sin(t * 5.0 + bx) * 3.0
			draw_circle(Vector2(pit.x + bx + 6, yy), 3, Color("#ffe08a"))
			bx += 12
	else:
		draw_rect(Rect2(pit.x, ground_y, pit.w, 300), Color("#05060c"))

func _draw_spike(sp: Dictionary) -> void:
	var spike_count: int = max(1, int(floor(sp.w / 12.0)))
	var sw: float = sp.w / float(spike_count)
	for i in range(spike_count):
		var pts := PackedVector2Array([
			Vector2(sp.x + i * sw, sp.y + sp.h),
			Vector2(sp.x + i * sw + sw / 2.0, sp.y),
			Vector2(sp.x + i * sw + sw, sp.y + sp.h),
		])
		draw_colored_polygon(pts, Color("#c7c7d1"))
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2]]), Color(0, 0, 0, 0.35), 1.0)

func _draw_flag() -> void:
	if not level_data.has("flag_x"):
		return
	var fx: float = level_data.flag_x
	var ground_y: float = Game.GROUND_Y
	draw_rect(Rect2(fx, ground_y - 120, 6, 120), Color("#c9a227"))
	var flag_color: Color = Color("#8e44ad") if (level_data.get("boss_arena", false) or level_data.get("has_mini_boss", false)) else Color("#e0435c")
	var pts := PackedVector2Array([
		Vector2(fx + 6, ground_y - 120), Vector2(fx + 46, ground_y - 104), Vector2(fx + 6, ground_y - 88),
	])
	draw_colored_polygon(pts, flag_color)
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), Color(0, 0, 0, 0.3), 1.0)
