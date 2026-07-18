extends Node2D
class_name FartLayer
## Draws the Royal Jam boost particle trail. Ported from drawFartParticles().

var particles: Array = []

func _draw() -> void:
	for p in particles:
		var alpha: float = clamp(p.life / 30.0, 0.0, 1.0) * 0.6
		var radius: float = 4.0 + (30.0 - p.life) * 0.15
		draw_circle(Vector2(p.x, p.y), radius, Color(155.0 / 255.0, 210.0 / 255.0, 120.0 / 255.0, alpha))
