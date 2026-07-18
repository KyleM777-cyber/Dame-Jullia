extends Node2D
class_name Chugger
## Small patrol enemy ("Chugger"). Visuals ported from the active drawChugger(e)
## in index.html (apple / honey / cheese variants). Update logic lives in Level.gd,
## mirroring the original's flat updateEnemies() function.

const W := 30.0
const H := 42.0

var vx := 1.4
var min_x := 0.0
var max_x := 0.0
var hp := 1
var max_hp := 1
var alive := true
var hurt_timer := 0
var wobble := 0.0
var knockback := 0
var knock_vx := 0.0
var kind := "cheese"

func get_rect() -> Rect2:
	return Rect2(position.x, position.y, W, H)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not alive:
		return
	var flash: bool = hurt_timer > 0 and int(hurt_timer / 3.0) % 2 == 0
	var body_color: Color
	var c := Vector2(15, 22 + wobble)

	match kind:
		"apple":
			body_color = Color("#ffffff") if flash else Color("#c9383c")
			draw_circle(c + Vector2(0, 5), 17, body_color)
			draw_arc(c + Vector2(0, 5), 17, 0, TAU, 32, Color("#2a1a16"), 1.2)
			draw_rect(Rect2(c + Vector2(-2, -18), Vector2(4, 10)), Color("#5c3a1e"))
			_draw_ellipse(c + Vector2(8, -14), 8, 4, -0.5, Color("#4c934e"))
		"honey":
			body_color = Color("#ffffff") if flash else Color("#e5ad28")
			draw_rect(Rect2(c + Vector2(-15, -15), Vector2(30, 40)), body_color)
			draw_rect(Rect2(c + Vector2(-15, -15), Vector2(30, 40)), Color("#2a1a16"), false, 1.2)
			draw_rect(Rect2(c + Vector2(-12, 0), Vector2(24, 14)), Color("#fff1b2"))
			draw_rect(Rect2(c + Vector2(-10, -20), Vector2(20, 6)), Color("#8b5d22"))
		_:
			body_color = Color("#ffffff") if flash else Color("#f0dfa7")
			var pts := PackedVector2Array([c + Vector2(-17, 20), c + Vector2(-17, -10), c + Vector2(17, -16), c + Vector2(17, 20)])
			draw_colored_polygon(pts, body_color)
			draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color("#2a1a16"), 1.2)
			draw_circle(c + Vector2(5, -2), 3, Color("#c7b56f"))
			draw_circle(c + Vector2(-7, 10), 3, Color("#c7b56f"))

	draw_rect(Rect2(c + Vector2(-9, -1), Vector2(4, 4)), Color("#241611"))
	draw_rect(Rect2(c + Vector2(5, -1), Vector2(4, 4)), Color("#241611"))
	draw_rect(Rect2(c + Vector2(-5, 8), Vector2(10, 2)), Color("#241611"))
	draw_rect(Rect2(c + Vector2(-12, 22), Vector2(7, 5)), Color("#3a2b25"))
	draw_rect(Rect2(c + Vector2(5, 22), Vector2(7, 5)), Color("#3a2b25"))

	for i in range(max_hp):
		var col := Color("#e0435c") if i < hp else Color("#33222a")
		draw_rect(Rect2(Vector2(2 + i * 8, -10), Vector2(6, 5)), col)

func _draw_ellipse(center: Vector2, rx: float, ry: float, rot: float, color: Color) -> void:
	var pts := PackedVector2Array()
	var steps := 20
	for i in range(steps + 1):
		var t: float = TAU * i / steps
		var p := Vector2(cos(t) * rx, sin(t) * ry).rotated(rot)
		pts.append(center + p)
	draw_colored_polygon(pts, color)
