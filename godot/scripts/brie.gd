extends Node2D
class_name Brie
## Final boss "Brie" (internally "jeb" in the original source — the boss-fight
## state machine is named jeb throughout index.html, a leftover from before the
## game was reskinned; dialogue correctly calls her Brie). Visuals ported from
## the active (cheese-wheel) drawJeb() override.

const W := 130.0
const H := 140.0

var hp := 14
var max_hp := 14
var facing_p := -1
var state := "idle"
var timer := 0
var action_cooldown := 80
var hurt_timer := 0
var fleeing := false
var enraged := false

var _pivot := Vector2.ZERO
var _flip := 1.0

func get_rect() -> Rect2:
	return Rect2(position.x, position.y, W, H)

func _process(_delta: float) -> void:
	queue_redraw()

func _pt(x: float, y: float) -> Vector2:
	return _pivot + Vector2(x * _flip, y)

func _draw() -> void:
	var flash: bool = hurt_timer > 0 and int(hurt_timer / 3.0) % 2 == 0
	_pivot = Vector2(65, 65)
	_flip = float(facing_p)

	var rind: Color = Color.WHITE if flash else Color("#efe0ab")
	_ellipse_fill(_pt(0, 5), 58, 58, rind)
	draw_arc(_pt(0, 5), 58, 0, TAU, 48, Color("#3d3021"), 2.0)

	# lighter half-moon highlight across the lower half of the wheel.
	var highlight := PackedVector2Array()
	var steps := 24
	for i in range(steps + 1):
		var t: float = PI + (PI * i / steps)
		highlight.append(_pt(cos(t) * 47.0, sin(t) * 47.0))
	draw_colored_polygon(highlight, Color("#fff7d5"))

	# rind holes
	_circle(_pt(-28, 12), 6, Color("#c8b46d"))
	_circle(_pt(24, -8), 5, Color("#c8b46d"))
	_circle(_pt(12, 28), 7, Color("#c8b46d"))

	# cheese-wedge crown
	var crown := PackedVector2Array([_pt(-40, -38), _pt(-20, -75), _pt(0, -45), _pt(20, -75), _pt(42, -38)])
	draw_colored_polygon(crown, Color("#d9b63e"))
	draw_polyline(PackedVector2Array([crown[0], crown[1], crown[2], crown[3], crown[4], crown[0]]), Color("#3d3021"), 2.0)

	draw_rect(_rect(-27, -5, 10, 8), Color("#332419"))
	draw_rect(_rect(17, -5, 10, 8), Color("#332419"))
	draw_rect(_rect(-18, 22, 36, 5), Color("#332419"))

	var cape := PackedVector2Array([_pt(-45, 20), _pt(-70, 70), _pt(-25, 58)])
	draw_colored_polygon(cape, Color("#7c315f"))
	draw_polyline(PackedVector2Array([cape[0], cape[1], cape[2], cape[0]]), Color("#3d3021"), 2.0)

func _rect(x0: float, y0: float, w: float, h: float) -> Rect2:
	var tx := x0 if _flip > 0 else -(x0 + w)
	return Rect2(_pivot + Vector2(tx, y0), Vector2(w, h))

func _circle(center: Vector2, r: float, color: Color) -> void:
	draw_circle(center, r, color)

func _ellipse_fill(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	var steps := 40
	for i in range(steps + 1):
		var t: float = TAU * i / steps
		pts.append(center + Vector2(cos(t) * rx, sin(t) * ry))
	draw_colored_polygon(pts, color)
