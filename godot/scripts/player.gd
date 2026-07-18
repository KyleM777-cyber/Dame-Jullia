extends Node2D
class_name Player
## Dame Julia. Ported 1:1 from updatePlayer()/moveAndCollide() in index.html.
## Position (x,y) is the AABB TOP-LEFT corner, matching the original's convention.
## Physics runs on Godot's fixed 60Hz physics tick (see project.godot), so every
## constant below is used exactly as it was in the original per-frame JS model —
## no delta-time scaling needed.

signal died

const W := 34.0
const H := 46.0
const GRAVITY := 0.58
const SPEED := 3.6
const JUMP_POWER := 11.7
const MAX_JUMPS := 2

var vx := 0.0
var vy := 0.0
var on_ground := false
var facing := 1

var max_hp := 6
var hp := 6
var attacking := false
var attack_timer := 0
var attack_cooldown := 0
var hurt_timer := 0
var jumps_used := 0
var hit_this_swing: Array = []

var ammo := 20
var max_ammo := 20
var fire_cooldown := 0

var dodging := false
var dodge_timer := 0
var dodge_cooldown := 0

var has_fart_boost := false
var fart_cooldown := 0
var max_fart_cooldown := 420

var jump_queued := false

@onready var sprite: AnimatedSprite2D = $Sprite

const ANIMATIONS := {
	"idle": {"row": 0, "frames": 4, "frame_ms": 190},
	"run": {"row": 1, "frames": 6, "frame_ms": 115},
	"jump": {"row": 0, "frames": 1, "frame_ms": 1000},
	"attack": {"row": 2, "frames": 6, "frame_ms": 70},
	"ranged": {"row": 3, "frames": 5, "frame_ms": 80},
	"hurt": {"row": 4, "frames": 2, "frame_ms": 120},
	"dodge": {"row": 5, "frames": 4, "frame_ms": 75},
	"victory": {"row": 6, "frames": 2, "frame_ms": 220},
	"dead": {"row": 4, "frames": 2, "frame_ms": 300},
}

func get_rect() -> Rect2:
	return Rect2(position.x, position.y, W, H)

func reset_for_level() -> void:
	position = Vector2(60, 300)
	vx = 0.0
	vy = 0.0
	max_hp = Game.player_max_hp
	hp = max_hp
	attacking = false
	attack_timer = 0
	attack_cooldown = 0
	hurt_timer = 0
	jumps_used = 0
	ammo = max_ammo
	fire_cooldown = 0
	dodging = false
	dodge_timer = 0
	dodge_cooldown = 0
	has_fart_boost = Game.player_has_fart_boost
	fart_cooldown = 0

func attack_hitbox() -> Rect2:
	const REACH := 30.0
	if facing == 1:
		return Rect2(position.x + W, position.y + 8, REACH, H - 16)
	else:
		return Rect2(position.x - REACH, position.y + 8, REACH, H - 16)

func queue_jump() -> void:
	jump_queued = true

func damage(amount: int, knock_dir: int) -> void:
	if hurt_timer > 0 or dodging:
		return
	hp -= amount
	hurt_timer = 50
	vx = knock_dir * 6.0
	vy = -4.0
	if hp <= 0:
		hp = 0
		died.emit()

## Called each physics tick by Level with input flags + fart particle spawn callback.
func step(move_dir: int, attack_pressed: bool, fire_pressed: bool,
		dodge_pressed: bool, fart_pressed: bool, spawn_fart: Callable, spawn_arrow: Callable) -> void:
	if hurt_timer > 0:
		hurt_timer -= 1
	if attack_cooldown > 0:
		attack_cooldown -= 1
	if fire_cooldown > 0:
		fire_cooldown -= 1
	if dodge_cooldown > 0:
		dodge_cooldown -= 1

	vx = move_dir * SPEED
	if move_dir != 0:
		facing = move_dir

	if dodge_pressed and dodge_cooldown <= 0 and not dodging:
		dodging = true
		dodge_timer = 12
		dodge_cooldown = 45

	if dodging:
		vx = facing * 9.0
		dodge_timer -= 1
		if dodge_timer <= 0:
			dodging = false

	if jump_queued:
		jump_queued = false
		if on_ground:
			vy = -JUMP_POWER
			on_ground = false
			jumps_used = 1
		elif jumps_used < MAX_JUMPS:
			vy = -JUMP_POWER * 0.85
			jumps_used += 1

	if attack_pressed and attack_cooldown <= 0 and not attacking:
		attacking = true
		attack_timer = 16
		attack_cooldown = 26
		hit_this_swing.clear()
	if attacking:
		attack_timer -= 1
		if attack_timer <= 0:
			attacking = false

	if fire_pressed and fire_cooldown <= 0 and ammo > 0:
		fire_cooldown = 20
		ammo -= 1
		var arrow_x: float = position.x + W if facing == 1 else position.x - 12.0
		spawn_arrow.call(arrow_x, position.y + H / 2.0 - 3.0, facing * 9.0)

	if fart_cooldown > 0:
		fart_cooldown -= 1
	if fart_pressed and has_fart_boost and fart_cooldown <= 0:
		fart_cooldown = max_fart_cooldown
		vy = -15.0
		vx = facing * 4.0
		jumps_used = 0
		for i in range(8):
			spawn_fart.call(position.x + W / 2.0, position.y + H)

	vy += GRAVITY
	vy = clamp(vy, -30.0, 18.0)

## Called by Level AFTER moveAndCollide resolves this frame's position/on_ground,
## matching the original where render() (and its frame selection) runs after
## updatePlayer() completes for the frame.
func update_animation() -> void:
	var anim_name := _current_animation_name()
	var anim: Dictionary = ANIMATIONS[anim_name]
	if sprite.animation != anim_name:
		sprite.animation = anim_name
		sprite.stop()

	var frame := 0
	if anim_name == "attack":
		frame = min(anim.frames - 1, int(floor((1.0 - float(attack_timer) / 16.0) * anim.frames)))
	elif anim_name == "dodge":
		frame = min(anim.frames - 1, int(floor((1.0 - float(dodge_timer) / 12.0) * anim.frames)))
	elif anim_name == "ranged":
		frame = min(anim.frames - 1, int(floor((20.0 - float(fire_cooldown)) / 7.0)))
	else:
		frame = int(floor(Time.get_ticks_msec() / float(anim.frame_ms))) % int(anim.frames)
	frame = clamp(frame, 0, int(anim.frames) - 1)
	sprite.frame = frame

	# Mirror around the box's horizontal center (matches ctx.scale(facing,1) pivot).
	if facing == 1:
		sprite.position = Vector2(34, 4)
		sprite.flip_h = false
	else:
		sprite.position = Vector2(0, 4)
		sprite.flip_h = true

func _current_animation_name() -> String:
	if hp <= 0:
		return "dead"
	if hurt_timer > 0:
		return "hurt"
	if dodging:
		return "dodge"
	if attacking:
		return "attack"
	if fire_cooldown > 13:
		return "ranged"
	if not on_ground:
		return "jump"
	if abs(vx) > 0.15:
		return "run"
	return "idle"
