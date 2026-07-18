extends Node2D
class_name MiniBoss
## Mini-boss (Sir Apple / Baron Honey). Visuals ported from the active
## drawMiniBoss() override in index.html.

const W := 74.0
const H := 74.0

var hp := 6
var max_hp := 6
var facing_p := -1
var state := "idle"
var timer := 0
var action_cooldown := 60
var hurt_timer := 0
var spray_count := 0
var kind := "apple"
var tie_color := Color("#8a1f2a")

var _pivot := Vector2.ZERO
var _flip := 1.0

func get_rect() -> Rect2:
	return Rect2(position.x, position.y, W, H)

func _process(_delta: float) -> void:
	queue_redraw()

## Mirrors a point the way ctx.scale(facing, 1) would (around local x = 0).
func _pt(x: float, y: float) -> Vector2:
	return _pivot + Vector2(x * _flip, y)

## Mirrors an axis-aligned rect (given in unflipped local space) the way
## ctx.scale(facing,1); fillRect(x0,y0,w,h) would — flipping negates BOTH edges.
func _rect(x0: float, y0: float, w: float, h: float) -> Rect2:
	var tx := x0 if _flip > 0 else -(x0 + w)
	return Rect2(_pivot + Vector2(tx, y0), Vector2(w, h))

func _draw() -> void:
	var flash: bool = hurt_timer > 0 and int(hurt_timer / 3.0) % 2 == 0
	var bob := sin(Time.get_ticks_msec() / 260.0) * 2.0
	_pivot = Vector2(37, 37 + bob)
	_flip = float(facing_p)

	if kind == "apple":
		var body: Color = Color.WHITE if flash else Color("#c7383d")
		draw_circle(_pt(0, 5), 34, body)
		draw_arc(_pt(0, 5), 34, 0, TAU, 40, Color("#2a1812"), 2.0)
		draw_rect(_rect(-4, -38, 8, 18), Color("#5d3b1e"))
		_ellipse(_pt(15, -30), 16, 7, -0.5 * _flip, Color("#4f9851"))
	else:
		var body: Color = Color.WHITE if flash else Color("#e4aa25")
		draw_rect(_rect(-30, -35, 60, 72), body)
		draw_rect(_rect(-30, -35, 60, 72), Color("#2a1812"), false, 2.0)
		draw_rect(_rect(-22, -45, 44, 12), Color("#8b5d22"))
		draw_rect(_rect(-24, -5, 48, 28), Color("#fff0af"))

	draw_rect(_rect(-17, -7, 8, 7), Color("#241611"))
	draw_rect(_rect(9, -7, 8, 7), Color("#241611"))
	draw_rect(_rect(-12, 14, 24, 4), Color("#241611"))

	var crown := PackedVector2Array([_pt(-24, -30), _pt(0, -58), _pt(24, -30)])
	draw_colored_polygon(crown, Color("#d5b54a"))
	draw_polyline(PackedVector2Array([crown[0], crown[1], crown[2], crown[0]]), Color("#2a1812"), 2.0)

func _ellipse(center: Vector2, rx: float, ry: float, rot: float, color: Color) -> void:
	var pts := PackedVector2Array()
	var steps := 24
	for i in range(steps + 1):
		var t: float = TAU * i / steps
		pts.append(center + Vector2(cos(t) * rx, sin(t) * ry).rotated(rot))
	draw_colored_polygon(pts, color)
