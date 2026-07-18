extends Node2D
class_name Projectile
## Generic projectile: player arrow, Brie's fire-ember shot, or mini-boss spray.
## Position is the AABB top-left, matching the original p.x/p.y convention.

var w := 12.0
var h := 5.0
var vx := 0.0
var kind := "arrow"  # arrow | ember | spray

func get_rect() -> Rect2:
	return Rect2(position.x, position.y, w, h)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	match kind:
		"arrow":
			var pivot := Vector2(w / 2.0, h / 2.0)
			var flip: float = -1.0 if vx < 0 else 1.0
			var shaft_x0 := -w / 2.0
			var shaft_w := w - 3.0
			var shaft_tx := shaft_x0 if flip > 0 else -(shaft_x0 + shaft_w)
			draw_rect(Rect2(pivot + Vector2(shaft_tx, -1), Vector2(shaft_w, 2)), Color("#c9a227"))
			var tip := PackedVector2Array([
				pivot + Vector2((w / 2.0 - 3) * flip, -3),
				pivot + Vector2((w / 2.0 + 2) * flip, 0),
				pivot + Vector2((w / 2.0 - 3) * flip, 3),
			])
			draw_colored_polygon(tip, Color("#e8e8f0"))
		"ember":
			var center := Vector2(8, 6)
			draw_circle(center, 12, Color(1.0, 0.83, 0.29, 0.35))
			draw_circle(center, 8, Color("#ffb347"))
			draw_circle(center, 4, Color("#ffe08a"))
		"spray":
			var center2 := Vector2(5, 5)
			draw_circle(center2, 5, Color("#e07b1f"))
			draw_arc(center2, 5, 0, TAU, 16, Color(0, 0, 0, 0.3), 1.0)
