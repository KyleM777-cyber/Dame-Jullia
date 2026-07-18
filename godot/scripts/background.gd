extends Node2D
class_name GameBackground
## Simplified parallax sky, ported loosely from drawBackground() in index.html.
## Parented directly to the Camera2D so it always fills the viewport; the
## far/near layers read the camera's world position themselves to scroll
## slower than the foreground, approximating the original's camX*factor look.

@export var theme: String = "orchard"

const VIEW_W := 960.0
const VIEW_H := 540.0

func _process(_delta: float) -> void:
	queue_redraw()

func _cam_x() -> float:
	var cam := get_parent()
	if cam is Camera2D:
		return cam.position.x
	return 0.0

func _sky_colors() -> Array:
	match theme:
		"castle":
			return [Color("#5fb8e8"), Color("#a9dcf2"), Color("#e3f4fa")]
		"forest":
			return [Color("#0f2a1c"), Color("#1f4a30"), Color("#3f7a4d")]
		"orchard":
			return [Color("#87ceeb"), Color("#bfe6f5"), Color("#e3f4fa")]
		"honey":
			return [Color("#2f4d3a"), Color("#3f6b4d"), Color("#5c8a5f")]
		_:
			return [Color("#0a0512"), Color("#1c0e28"), Color("#3a1c38")]

func _draw() -> void:
	var half_w := VIEW_W / 2.0
	var half_h := VIEW_H / 2.0
	var colors := _sky_colors()
	var band_h := VIEW_H / 3.0
	draw_rect(Rect2(-half_w, -half_h, VIEW_W, band_h + 1), colors[0])
	draw_rect(Rect2(-half_w, -half_h + band_h, VIEW_W, band_h + 1), colors[1])
	draw_rect(Rect2(-half_w, -half_h + band_h * 2, VIEW_W, band_h + 2), colors[2])

	var cam_x := _cam_x()
	var sky_local_x: float = -half_w + 780.0 - cam_x * 0.1 - (-cam_x)
	# The sky glow drifts far slower than the camera (factor 0.1 of camera motion).
	var glow_x: float = 780.0 - cam_x * 0.1 - cam_x
	var glow_center := Vector2(glow_x, -half_h + 90)
	if theme == "castle" or theme == "orchard":
		draw_circle(glow_center, 46, Color(1, 0.98, 0.82, 0.35))
		draw_circle(glow_center, 26, Color("#fff6d0"))
	elif theme == "honey":
		draw_circle(glow_center, 40, Color(1, 1, 0.9, 0.25))
	else:
		draw_circle(glow_center, 22, Color("#1c0e28"))
		draw_circle(glow_center + Vector2(9, -6), 20, Color(colors[0].r, colors[0].g, colors[0].b))
		for i in range(30):
			var sx: float = fmod(i * 137.0, VIEW_W) - half_w
			var sy: float = fmod(i * 53.0, 220.0) - half_h
			draw_rect(Rect2(sx, sy, 2, 2), Color(1, 1, 1, 0.2 + float(i % 5) * 0.12))

	# mid-layer silhouettes, parallax factor ~0.35 of camera motion.
	var par_x: float = -cam_x * 0.35 - cam_x
	var silhouette: Color = Color("#c9e8f5") if theme in ["orchard", "castle"] else (Color("#3f6b4d") if theme == "honey" else Color("#3a1c38"))
	silhouette.a = 0.5
	for i in range(-1, 8):
		var bx: float = fmod(i * 260.0 + par_x, 260.0 * 9.0) - half_w
		draw_colored_polygon(PackedVector2Array([
			Vector2(bx, half_h), Vector2(bx + 20, half_h - 110), Vector2(bx + 40, half_h),
		]), silhouette)
