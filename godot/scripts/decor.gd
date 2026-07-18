extends Node2D
class_name Decor
## Background decoration. Ported from drawDecor() in index.html. Uses this
## node's own `scale` for the per-instance scale factor instead of manually
## scaling every coordinate, since Godot's Node2D already supports that.

var type := "bush"
var theme := ""

func _draw() -> void:
	match type:
		"tree":
			draw_rect(Rect2(-6, -50, 12, 50), Color("#4a3320"))
			draw_rect(Rect2(-6, -50, 12, 50), Color(0, 0, 0, 0.3), false, 1.0)
			var green: Color = Color("#5a4a6a") if theme == "lair" else Color("#2f6b3a")
			draw_circle(Vector2(0, -70), 30, green)
			draw_circle(Vector2(-20, -55), 22, green)
			draw_circle(Vector2(20, -55), 22, green)
		"bush":
			var green2: Color
			if theme == "castle":
				green2 = Color("#3f7a45")
			elif theme == "lair":
				green2 = Color("#4a3a5a")
			else:
				green2 = Color("#356b3f")
			draw_circle(Vector2(-12, -8), 14, green2)
			draw_circle(Vector2(6, -12), 17, green2)
			draw_circle(Vector2(20, -8), 12, green2)
		"rock":
			var grey: Color = Color("#3a2c3a") if theme == "lair" else Color("#8a8a8a")
			var pts := PackedVector2Array([Vector2(-18, 0), Vector2(-14, -18), Vector2(2, -26), Vector2(18, -14), Vector2(16, 0)])
			draw_colored_polygon(pts, grey)
			var outline := pts.duplicate()
			outline.append(pts[0])
			draw_polyline(outline, Color(0, 0, 0, 0.3), 1.0)
			draw_colored_polygon(PackedVector2Array([Vector2(-14, -18), Vector2(2, -26), Vector2(-2, -10)]), Color(1, 1, 1, 0.12))
		"stalagmite":
			draw_colored_polygon(PackedVector2Array([Vector2(-14, 0), Vector2(0, -46), Vector2(14, 0)]), Color("#4a3a55"))
		"bones":
			draw_line(Vector2(-16, -4), Vector2(14, -12), Color("#d8cfc0"), 5.0, true)
			draw_line(Vector2(-10, -14), Vector2(10, 2), Color("#d8cfc0"), 5.0, true)
		"shelf":
			draw_rect(Rect2(-22, -70, 6, 70), Color("#5a5a62"))
			draw_rect(Rect2(16, -70, 6, 70), Color("#5a5a62"))
			draw_rect(Rect2(-22, -70, 44, 5), Color("#787882"))
			draw_rect(Rect2(-22, -40, 44, 5), Color("#787882"))
			draw_rect(Rect2(-22, -10, 44, 5), Color("#787882"))
			var box_colors := [Color("#c0521c"), Color("#e8c766"), Color("#8a1f2a"), Color("#2ab88a")]
			var i := 0
			var bx := -18
			while bx < 16:
				var col: Color = box_colors[int(abs(bx + position.x)) % box_colors.size()]
				draw_rect(Rect2(bx, -65, 9, 20), col)
				draw_rect(Rect2(bx, -35, 9, 20), col)
				bx += 12
				i += 1
			draw_rect(Rect2(-22, -70, 44, 70), Color(0, 0, 0, 0.3), false, 1.0)
		"cart":
			draw_rect(Rect2(-16, -22, 32, 18), Color("#9aa0a8"), false, 2.5)
			draw_line(Vector2(-16, -22), Vector2(-22, -30), Color("#9aa0a8"), 2.5)
			draw_line(Vector2(-22, -30), Vector2(-12, -30), Color("#9aa0a8"), 2.5)
			draw_circle(Vector2(-10, 0), 4, Color("#2b2018"))
			draw_circle(Vector2(10, 0), 4, Color("#2b2018"))
			draw_rect(Rect2(-10, -34, 14, 8), Color("#e8c766"))
		"sign":
			draw_line(Vector2(0, 0), Vector2(0, -50), Color("#5a5a62"), 2.0)
			draw_rect(Rect2(-30, -70, 60, 22), Color("#c0521c"))
			draw_rect(Rect2(-30, -70, 60, 22), Color(0, 0, 0, 0.4), false, 1.0)
			var font := ThemeDB.fallback_font
			draw_string(font, Vector2(-27, -54), "CLEARANCE", HORIZONTAL_ALIGNMENT_CENTER, 54, 10, Color("#fff6d0"))
