extends Node2D
class_name HangingRock
## Hanging pantry stone in the Brie boss arenas. Ported from drawRocks()/updateRocks().

const W := 50.0
const H := 90.0

var state := "hanging"  # hanging | falling | gone
var vy := 0.0
var respawn_timer := 0
var shake := 0.0

func get_rect() -> Rect2:
	return Rect2(position.x, position.y, W, H)

func _process(_delta: float) -> void:
	visible = state != "gone"
	queue_redraw()

func _draw() -> void:
	if state == "gone":
		return
	var wobble: float = sin(shake) * 3.0 if state == "hanging" else 0.0
	var top := Vector2(W / 2.0 + wobble, 0)

	var pts := PackedVector2Array([
		top + Vector2(-W / 2.0, 0), top + Vector2(W / 2.0, 0), top + Vector2(W / 2.0 - 6, H * 0.6),
		top + Vector2(0, H), top + Vector2(-W / 2.0 + 6, H * 0.6),
	])
	draw_colored_polygon(pts, Color("#4d3f4d"))
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, Color(0, 0, 0, 0.4), 1.5)

	if state == "hanging":
		draw_line(top + Vector2(0, -30), top, Color(120.0 / 255.0, 100.0 / 255.0, 120.0 / 255.0, 0.5), 1.0)
