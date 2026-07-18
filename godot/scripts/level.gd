extends Node2D
class_name Level
## Ported from the update*/render section of index.html: moveAndCollide,
## updatePlayer, updateEnemies, updatePlayerProjectiles, updateJeb (Brie),
## updateMiniBoss, updateRocks, updateMovingPlatforms, and the level-flow
## dialogue chain (miniBossIntroDialogue, jebIntroDialogue, etc).

const ChuggerScene := preload("res://scenes/entities/Chugger.tscn")
const MiniBossScene := preload("res://scenes/entities/MiniBoss.tscn")
const BrieScene := preload("res://scenes/entities/Brie.tscn")
const ProjectileScene := preload("res://scenes/entities/Projectile.tscn")
const HangingRockScene := preload("res://scenes/entities/HangingRock.tscn")
const DecorScene := preload("res://scenes/entities/Decor.tscn")
const PlayerScene := preload("res://scenes/entities/Player.tscn")

signal player_died
signal level_completed(outro_text: String)
signal victory_reached
signal boss_bar_changed(visible_: bool, name_: String, pct: float)

@onready var camera: Camera2D = $Camera2D
@onready var terrain: Terrain = $Terrain
@onready var decor_layer: Node2D = $DecorLayer
@onready var rocks_layer: Node2D = $RocksLayer
@onready var enemies_layer: Node2D = $EnemiesLayer
@onready var boss_layer: Node2D = $BossLayer
@onready var boss_proj_layer: Node2D = $BossProjLayer
@onready var mini_layer: Node2D = $MiniLayer
@onready var mini_proj_layer: Node2D = $MiniProjLayer
@onready var player_proj_layer: Node2D = $PlayerProjLayer
@onready var fart_layer: FartLayer = $FartLayer
@onready var player_anchor: Node2D = $PlayerAnchor
@onready var background: GameBackground = $Camera2D/Background

var player: Player
var level_data: Dictionary = {}
var level_width: float = 0.0

var enemies: Array = []
var mini_boss: MiniBoss = null
var mini_boss_active := false
var mini_boss_defeated := false
var mini_boss_projectiles: Array = []

var brie: Brie = null
var boss_active := false
var boss_defeated := false
var brie_projectiles: Array = []
var rocks: Array = []

var player_projectiles: Array = []
var fart_particles: Array = []

var flag_reached := false
var friar_shown := false

var moving_platform_states: Array = []  # {data, rect}

func _ready() -> void:
	pass

func setup(index: int) -> void:
	level_data = Game.LEVELS[index]
	level_width = float(level_data.width)

	player = PlayerScene.instantiate() as Player
	player_anchor.add_child(player)
	player.reset_for_level()
	player.died.connect(_on_player_died)

	terrain.level_data = level_data
	terrain.queue_redraw()
	background.theme = level_data.theme

	_spawn_decor()
	_spawn_enemies()
	_init_moving_platforms()

	brie = null
	boss_active = false
	boss_defeated = false
	brie_projectiles.clear()
	rocks.clear()

	mini_boss = null
	mini_boss_active = false
	mini_boss_defeated = false
	mini_boss_projectiles.clear()

	flag_reached = false
	friar_shown = false
	player_projectiles.clear()
	fart_particles.clear()

	camera.position = Vector2(clamp(player.position.x, Game.VIEW_W / 2.0, max(Game.VIEW_W / 2.0, level_width - Game.VIEW_W / 2.0)), Game.VIEW_H / 2.0)

	boss_bar_changed.emit(false, "", 1.0)

	Game.set_state("playing")
	if level_data.has("intro") and not level_data.intro.is_empty():
		Game.start_dialogue(level_data.intro)

func _spawn_decor() -> void:
	for child in decor_layer.get_children():
		child.queue_free()
	for d in level_data.get("decor", []):
		var inst: Decor = DecorScene.instantiate() as Decor
		decor_layer.add_child(inst)
		inst.type = d.type
		inst.theme = level_data.theme
		inst.position = Vector2(d.x, Game.GROUND_Y)
		inst.scale = Vector2(d.scale, d.scale)

func _spawn_enemies() -> void:
	for child in enemies_layer.get_children():
		child.queue_free()
	enemies.clear()
	var base_hp: int = level_data.get("enemy_hp", 1)
	for e in level_data.get("enemies", []):
		var c: Chugger = ChuggerScene.instantiate() as Chugger
		enemies_layer.add_child(c)
		c.position = Vector2(e.x, Game.GROUND_Y - 42)
		c.vx = 1.4
		c.min_x = e.min
		c.max_x = e.max
		c.hp = e.get("hp", base_hp)
		c.max_hp = c.hp
		c.alive = true
		c.hurt_timer = 0
		c.wobble = randf() * 10.0
		c.knockback = 0
		c.knock_vx = 0.0
		c.kind = level_data.get("enemy_kind", "cheese")
		enemies.append(c)

func _init_moving_platforms() -> void:
	moving_platform_states.clear()
	for mp in level_data.get("moving_platforms", []):
		mp.x = mp.base_x
		mp.y = mp.base_y
		moving_platform_states.append(mp)

# ================= COLLISION =================

func _static_platform_rects() -> Array:
	var out: Array = []
	for p in level_data.get("platforms", []):
		out.append(Rect2(p.x, p.y, p.w, p.h))
	return out

func _active_platform_rects() -> Array:
	var out := _static_platform_rects()
	for mp in moving_platform_states:
		out.append(Rect2(mp.x, mp.y, mp.w, mp.h))
	return out

## Ported from moveAndCollide(entity, platforms). `rect` must have .position/.size
## style access — here we operate directly on the Player node's position + W/H.
func _move_and_collide_player(platforms: Array) -> void:
	player.position.x += player.vx
	var pr := player.get_rect()
	for p in platforms:
		if pr.intersects(p):
			if player.vx > 0:
				player.position.x = p.position.x - Player.W
			elif player.vx < 0:
				player.position.x = p.position.x + p.size.x
			pr = player.get_rect()

	player.position.y += player.vy
	player.on_ground = false
	pr = player.get_rect()
	for p in platforms:
		if pr.intersects(p):
			if player.vy > 0:
				player.position.y = p.position.y - Player.H
				player.vy = 0
				player.on_ground = true
				player.jumps_used = 0
			elif player.vy < 0:
				player.position.y = p.position.y + p.size.y
				player.vy = 0
			pr = player.get_rect()

func _update_moving_platforms() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for mp in moving_platform_states:
		var old_x: float = mp.x
		var old_y: float = mp.y
		if mp.axis == "x":
			mp.x = mp.base_x + sin(t * mp.speed + mp.phase) * mp.range
		else:
			mp.y = mp.base_y + sin(t * mp.speed + mp.phase) * mp.range
		var dx: float = mp.x - old_x
		var dy: float = mp.y - old_y
		if player.on_ground:
			var on_top: bool = abs((player.position.y + Player.H) - mp.y) < 4.0 \
				and player.position.x + Player.W > mp.x and player.position.x < mp.x + mp.w
			if on_top:
				player.position.x += dx
				player.position.y += dy
	terrain.moving_platform_states = moving_platform_states
	terrain.queue_redraw()

# ================= MAIN TICK (called by Main._physics_process) =================

func tick(move_dir: int, attack: bool, fire: bool, dodge: bool, fart: bool) -> void:
	if Game.state != "playing":
		return

	player.step(move_dir, attack, fire, dodge, fart, _spawn_fart, _spawn_arrow)
	_update_moving_platforms()
	_move_and_collide_player(_active_platform_rects())

	_check_pits()
	_check_spikes()
	if player.position.y > Game.VIEW_H + 100:
		player.damage(1, 0)
		player.position = Vector2(60, 300)
		player.vy = 0

	player.position.x = clamp(player.position.x, 0, level_width - Player.W)
	camera.position = Vector2(clamp(player.position.x, Game.VIEW_W / 2.0, max(Game.VIEW_W / 2.0, level_width - Game.VIEW_W / 2.0)), Game.VIEW_H / 2.0)

	if not flag_reached and player.position.x + Player.W >= level_data.flag_x:
		if not level_data.get("boss_arena", false) and not level_data.get("has_mini_boss", false):
			flag_reached = true
			_on_level_complete()

	if level_data.get("boss_arena", false) and not boss_active and not boss_defeated and player.position.x > level_width - 500:
		_brie_intro_dialogue()
	if level_data.get("has_mini_boss", false) and not mini_boss_active and not mini_boss_defeated and player.position.x > level_width - 550:
		_mini_boss_intro_dialogue()
	if level_data.has("friar_x") and not friar_shown and player.position.x > level_data.friar_x:
		friar_shown = true
		Game.start_dialogue(Game.friar_lines())

	_update_enemies()
	_update_player_projectiles()
	_update_fart_particles()
	_update_brie()
	_update_rocks()
	_update_mini_boss()

	player.update_animation()

func _check_pits() -> void:
	for pit in level_data.get("pits", []):
		var pr := Rect2(pit.x, pit.y, pit.w, pit.h)
		if player.position.x + Player.W > pit.x and player.position.x < pit.x + pit.w and player.position.y + Player.H > Game.GROUND_Y + 10:
			player.damage(2 if pit.get("lava", false) else 1, 0)
			player.position.x = max(60.0, pit.x - 60.0)
			player.position.y = 300
			player.vy = 0

func _check_spikes() -> void:
	for sp in level_data.get("spikes", []):
		var sr := Rect2(sp.x, sp.y, sp.w, sp.h)
		if player.get_rect().intersects(sr) and player.hurt_timer <= 0:
			player.damage(1, -1 if player.position.x < sp.x + sp.w / 2.0 else 1)

func _spawn_fart(x: float, y: float) -> void:
	fart_particles.append({
		"x": x, "y": y,
		"vx": (randf() - 0.5) * 3.0, "vy": randf() * 2.0,
		"life": 24.0 + randf() * 10.0,
	})

func _spawn_arrow(x: float, y: float, vx: float) -> void:
	var p: Projectile = ProjectileScene.instantiate() as Projectile
	player_proj_layer.add_child(p)
	p.kind = "arrow"
	p.w = 12.0
	p.h = 5.0
	p.vx = vx
	p.position = Vector2(x, y)
	player_projectiles.append(p)

func _update_fart_particles() -> void:
	for p in fart_particles:
		p.x += p.vx
		p.y += p.vy
		p.vy += 0.1
		p.life -= 1
	fart_particles = fart_particles.filter(func(p): return p.life > 0)
	fart_layer.particles = fart_particles
	fart_layer.queue_redraw()

# ================= ENEMIES =================

func _update_enemies() -> void:
	var hitbox: Variant = player.attack_hitbox() if player.attacking else null
	for e in enemies:
		if not e.alive:
			continue
		if e.hurt_timer > 0:
			e.hurt_timer -= 1

		if e.knockback > 0:
			e.position.x += e.knock_vx
			e.knock_vx *= 0.86
			e.knockback -= 1
		else:
			var dist_to_player: float = player.position.x - e.position.x
			if abs(dist_to_player) < 320.0 and abs(player.position.y - e.position.y) < 130.0:
				e.vx = sign(dist_to_player) * 2.3
			else:
				if e.position.x <= e.min_x:
					e.vx = 1.4
				if e.position.x >= e.max_x:
					e.vx = -1.4
			e.position.x += e.vx
			e.position.x = clamp(e.position.x, e.min_x - 20.0, e.max_x + 20.0)
		e.wobble += 0.15

		if player.get_rect().intersects(e.get_rect()) and player.hurt_timer <= 0:
			var stomping: bool = player.vy > 0 and (player.position.y + Player.H) <= (e.position.y + 18.0)
			if stomping:
				e.alive = false
				player.vy = -9.0
			else:
				player.damage(1, -1 if player.position.x < e.position.x else 1)

		if hitbox != null and hitbox.intersects(e.get_rect()) and not player.hit_this_swing.has(e):
			player.hit_this_swing.append(e)
			e.hp -= 1
			e.hurt_timer = 14
			var knock_dir: int = -1 if e.position.x < player.position.x else 1
			e.knock_vx = knock_dir * 9.0
			e.knockback = 16
			if e.hp <= 0:
				e.alive = false

func _update_player_projectiles() -> void:
	for p in player_projectiles:
		p.position.x += p.vx

	for p in player_projectiles:
		if p.get_meta("dead", false):
			continue
		for e in enemies:
			if e.alive and p.get_rect().intersects(e.get_rect()):
				e.hp -= 1
				e.hurt_timer = 14
				e.knock_vx = (-1 if e.position.x < p.position.x else 1) * 9.0
				e.knockback = 16
				if e.hp <= 0:
					e.alive = false
				p.set_meta("dead", true)
				break
		if p.get_meta("dead", false):
			continue

		if brie != null and boss_active and p.get_rect().intersects(brie.get_rect()):
			_damage_brie(1)
			p.set_meta("dead", true)
			continue

		if mini_boss != null and mini_boss_active and p.get_rect().intersects(mini_boss.get_rect()):
			mini_boss.hp -= 1
			mini_boss.hurt_timer = 10
			_update_boss_bar(mini_boss)
			if mini_boss.hp <= 0:
				mini_boss_active = false
				mini_boss_defeated = true
				boss_bar_changed.emit(false, "", 1.0)
				_kings_congrats_dialogue()
			p.set_meta("dead", true)
			continue

	var kept: Array = []
	for p in player_projectiles:
		if p.get_meta("dead", false) or p.position.x < -50 or p.position.x > level_width + 50:
			p.queue_free()
		else:
			kept.append(p)
	player_projectiles = kept

# ================= BRIE (final boss; "jeb" in the original source) =================

func _spawn_brie() -> void:
	var hp: int = level_data.get("jeb_hp", 14)
	brie = BrieScene.instantiate() as Brie
	boss_layer.add_child(brie)
	brie.position = Vector2(level_width - 260, Game.GROUND_Y - 140)
	brie.hp = hp
	brie.max_hp = hp
	brie.facing_p = -1
	brie.state = "idle"
	brie.timer = 0
	brie.action_cooldown = level_data.get("jeb_action_cooldown", 80)
	brie.hurt_timer = 0
	brie.fleeing = false
	brie.enraged = false
	brie_projectiles.clear()
	boss_active = true
	boss_defeated = false

	rocks.clear()
	for r in level_data.get("arena_rocks", []):
		var rock: HangingRock = HangingRockScene.instantiate() as HangingRock
		rocks_layer.add_child(rock)
		rock.position = Vector2(r.x, 170)
		rock.state = "hanging"
		rock.vy = 0.0
		rock.respawn_timer = 0
		rock.shake = randf() * 10.0
		rocks.append(rock)

	boss_bar_changed.emit(true, "BRIE", 1.0)

func _brie_intro_dialogue() -> void:
	Game.start_dialogue(Game.brie_intro_lines(), Callable(self, "_spawn_brie"))

func _brie_flee_sequence() -> void:
	Game.start_dialogue(Game.brie_flee_lines(), Callable(self, "_friar_slide_dialogue"))

func _friar_slide_dialogue() -> void:
	Game.start_dialogue(Game.friar_slide_lines(), Callable(self, "_grant_jam_powerup"))

func _grant_jam_powerup() -> void:
	Game.player_max_hp += 2
	Game.player_has_fart_boost = true
	player.max_hp = Game.player_max_hp
	player.hp = player.max_hp
	player.has_fart_boost = true
	player.fart_cooldown = 0
	flag_reached = true
	_on_level_complete()

func _prince_kyle_dialogue() -> void:
	Game.start_dialogue(Game.prince_kyle_lines(), Callable(self, "_kings_finale_dialogue"))

func _kings_finale_dialogue() -> void:
	Game.start_dialogue(Game.kings_finale_lines(), Callable(self, "_reach_victory"))

func _reach_victory() -> void:
	Game.set_state("victory")
	victory_reached.emit()

func _mini_boss_intro_dialogue() -> void:
	Game.start_dialogue(level_data.mini_boss_intro, Callable(self, "_spawn_mini_boss"))

func _kings_congrats_dialogue() -> void:
	Game.start_dialogue(level_data.kings_congrats, func():
		flag_reached = true
		_on_level_complete()
	)

func _update_brie() -> void:
	if brie == null or not boss_active:
		return
	var hitbox: Variant = player.attack_hitbox() if player.attacking else null
	brie.facing_p = -1 if player.position.x < brie.position.x else 1
	if brie.hurt_timer > 0:
		brie.hurt_timer -= 1

	if not brie.enraged and brie.hp <= brie.max_hp * 0.4:
		brie.enraged = true
	var lunge_speed: float = 6.0 if brie.enraged else 4.0
	var lunge_dmg: int = 3 if brie.enraged else 2
	var cooldown_range: Array = [30, 55] if brie.enraged else [55, 90]
	var shot_speed: float = 9.0 if brie.enraged else 7.0

	brie.timer += 1
	if brie.timer > brie.action_cooldown and brie.state == "idle":
		var roll := randf()
		if roll < 0.6:
			brie.state = "breathe"
			brie.timer = 0
		else:
			brie.state = "lunge"
			brie.timer = 0

	if brie.state == "breathe":
		var shot_frames: Array = [12, 20, 28, 36, 44] if brie.enraged else [14, 24, 34, 44]
		if shot_frames.has(brie.timer):
			var spread: float = float(brie.timer - shot_frames[0]) - 8.0
			var proj: Projectile = ProjectileScene.instantiate() as Projectile
			boss_proj_layer.add_child(proj)
			proj.kind = "ember"
			proj.w = 16.0
			proj.h = 12.0
			proj.vx = brie.facing_p * shot_speed
			proj.position = Vector2(brie.position.x + (0 if brie.facing_p == -1 else Brie.W), brie.position.y + 55 + spread)
			brie_projectiles.append(proj)
		if brie.timer > 60:
			brie.state = "idle"
			brie.timer = 0
			brie.action_cooldown = cooldown_range[0] + randf() * (cooldown_range[1] - cooldown_range[0])
	elif brie.state == "lunge":
		var dir: int = brie.facing_p
		if brie.timer < 26:
			brie.position.x += dir * lunge_speed
		if brie.timer == 26 and player.get_rect().intersects(brie.get_rect()) and player.hurt_timer <= 0:
			player.damage(lunge_dmg, dir)
		if brie.timer > 46:
			brie.state = "idle"
			brie.timer = 0
			brie.action_cooldown = cooldown_range[0] + randf() * (cooldown_range[1] - cooldown_range[0])

	brie.position.x = clamp(brie.position.x, level_width - 700, level_width - Brie.W - 20)

	for p in brie_projectiles:
		p.position.x += p.vx
	var kept: Array = []
	for p in brie_projectiles:
		if p.position.x > -50 and p.position.x < level_width + 50:
			kept.append(p)
		else:
			p.queue_free()
	brie_projectiles = kept
	for p in brie_projectiles:
		if player.get_rect().intersects(p.get_rect()) and player.hurt_timer <= 0:
			player.damage(1, signi(p.vx))
			p.position.x = -9999

	if hitbox != null and hitbox.intersects(brie.get_rect()) and not player.hit_this_swing.has(brie):
		player.hit_this_swing.append(brie)
		_damage_brie(1)

func _damage_brie(amount: int) -> void:
	if brie == null or brie.fleeing:
		return
	brie.hp -= amount
	brie.hurt_timer = 14
	_update_boss_bar(brie)
	if level_data.get("jeb_flees_at_low_hp", false) and brie.hp <= 4:
		brie.fleeing = true
		boss_active = false
		_brie_flee_sequence()
		return
	if brie.hp <= 0:
		brie.hp = 0
		boss_active = false
		boss_defeated = true
		boss_bar_changed.emit(false, "", 1.0)
		_prince_kyle_dialogue()

func _update_boss_bar(boss: Node2D) -> void:
	var pct: float = max(0.0, float(boss.hp) / float(boss.max_hp))
	var display_name: String = "BRIE" if boss == brie else String(level_data.get("mini_boss_name", "BOSS")).to_upper()
	boss_bar_changed.emit(true, display_name, pct)

# ================= HANGING ROCKS =================

func _update_rocks() -> void:
	if rocks.is_empty():
		return
	var hitbox: Variant = player.attack_hitbox() if player.attacking else null
	for r in rocks:
		if r.state == "hanging":
			r.shake += 0.1
			var triggered: bool = hitbox != null and hitbox.intersects(r.get_rect())
			if not triggered:
				for p in player_projectiles:
					if not p.get_meta("dead", false) and p.get_rect().intersects(r.get_rect()):
						p.set_meta("dead", true)
						triggered = true
						break
			if triggered:
				r.state = "falling"
				r.vy = 1.0
		elif r.state == "falling":
			r.vy = min(r.vy + 0.75, 15.0)
			r.position.y += r.vy
			if brie != null and boss_active and r.get_rect().intersects(brie.get_rect()):
				_damage_brie(3)
				r.state = "gone"
				r.respawn_timer = 240
				continue
			if r.get_rect().intersects(player.get_rect()) and player.hurt_timer <= 0 and not player.dodging:
				player.damage(2, 0)
				r.state = "gone"
				r.respawn_timer = 240
				continue
			if r.position.y > Game.GROUND_Y - HangingRock.H:
				r.state = "gone"
				r.respawn_timer = 240
		elif r.state == "gone":
			r.respawn_timer -= 1
			if r.respawn_timer <= 0:
				r.state = "hanging"
				r.position.y = 170
				r.vy = 0.0

# ================= MINI-BOSS =================

func _spawn_mini_boss() -> void:
	mini_boss = MiniBossScene.instantiate() as MiniBoss
	mini_layer.add_child(mini_boss)
	mini_boss.position = Vector2(level_width - 260, Game.GROUND_Y - 74)
	mini_boss.hp = level_data.get("mini_boss_hp", 6)
	mini_boss.max_hp = mini_boss.hp
	mini_boss.facing_p = -1
	mini_boss.state = "idle"
	mini_boss.timer = 0
	mini_boss.action_cooldown = 60
	mini_boss.hurt_timer = 0
	mini_boss.spray_count = 0
	mini_boss.kind = level_data.get("mini_boss_kind", "apple")
	mini_boss.tie_color = Color(level_data.get("mini_boss_tie", "#8a1f2a"))
	mini_boss_projectiles.clear()
	mini_boss_active = true
	mini_boss_defeated = false
	boss_bar_changed.emit(true, String(level_data.get("mini_boss_name", "BOSS")).to_upper(), 1.0)

func _update_mini_boss() -> void:
	if mini_boss == null or not mini_boss_active:
		return
	var hitbox: Variant = player.attack_hitbox() if player.attacking else null
	mini_boss.facing_p = -1 if player.position.x < mini_boss.position.x else 1
	if mini_boss.hurt_timer > 0:
		mini_boss.hurt_timer -= 1

	mini_boss.timer += 1
	if mini_boss.timer > mini_boss.action_cooldown and mini_boss.state == "idle":
		var roll := randf()
		if roll < 0.5:
			mini_boss.state = "spray"
			mini_boss.timer = 0
			mini_boss.spray_count = 0
		else:
			mini_boss.state = "lunge"
			mini_boss.timer = 0

	if mini_boss.state == "spray":
		if mini_boss.timer % 10 == 0 and mini_boss.spray_count < 3:
			var proj: Projectile = ProjectileScene.instantiate() as Projectile
			mini_proj_layer.add_child(proj)
			proj.kind = "spray"
			proj.w = 10.0
			proj.h = 10.0
			proj.vx = mini_boss.facing_p * 7.0
			proj.position = Vector2(mini_boss.position.x + (0 if mini_boss.facing_p == -1 else MiniBoss.W), mini_boss.position.y + 30)
			mini_boss_projectiles.append(proj)
			mini_boss.spray_count += 1
		if mini_boss.timer > 45:
			mini_boss.state = "idle"
			mini_boss.timer = 0
			mini_boss.action_cooldown = 55 + randf() * 30.0
	elif mini_boss.state == "lunge":
		var dir: int = mini_boss.facing_p
		if mini_boss.timer < 20:
			mini_boss.position.x += dir * 4.5
		if mini_boss.timer == 20 and player.get_rect().intersects(mini_boss.get_rect()) and player.hurt_timer <= 0:
			player.damage(1, dir)
		if mini_boss.timer > 38:
			mini_boss.state = "idle"
			mini_boss.timer = 0
			mini_boss.action_cooldown = 55 + randf() * 30.0

	mini_boss.position.x = clamp(mini_boss.position.x, level_width - 500, level_width - MiniBoss.W - 20)

	for p in mini_boss_projectiles:
		p.position.x += p.vx
	var kept: Array = []
	for p in mini_boss_projectiles:
		if p.position.x > -50 and p.position.x < level_width + 50:
			kept.append(p)
		else:
			p.queue_free()
	mini_boss_projectiles = kept
	for p in mini_boss_projectiles:
		if player.get_rect().intersects(p.get_rect()) and player.hurt_timer <= 0:
			player.damage(1, signi(p.vx))
			p.position.x = -9999

	if hitbox != null and hitbox.intersects(mini_boss.get_rect()) and not player.hit_this_swing.has(mini_boss):
		player.hit_this_swing.append(mini_boss)
		mini_boss.hp -= 1
		mini_boss.hurt_timer = 10
		_update_boss_bar(mini_boss)
		if mini_boss.hp <= 0:
			mini_boss_active = false
			mini_boss_defeated = true
			boss_bar_changed.emit(false, "", 1.0)
			_kings_congrats_dialogue()

# ================= LEVEL FLOW =================

func _on_player_died() -> void:
	player_died.emit()

func _on_level_complete() -> void:
	level_completed.emit(level_data.get("outro", "Onward!"))

func signi(v: float) -> int:
	if v > 0:
		return 1
	if v < 0:
		return -1
	return 0
