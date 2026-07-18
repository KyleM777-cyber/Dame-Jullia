extends Node2D
## Root controller. Ported from the top-level DOM wiring in index.html
## (startBtn/nextLevelBtn/retryBtn/restartBtn onclick handlers + the
## keydown/keyup listeners that drive updatePlayer()).

const LevelScene := preload("res://scenes/levels/Level.tscn")

@onready var level_container: Node2D = $LevelContainer
@onready var hud: HUD = $UI/HUD
@onready var dialogue_box: DialogueBox = $UI/DialogueBox
@onready var overlay: GameOverlay = $UI/Overlay

var current_level: Level = null
var _pending_outro := ""

const START_BODY := "Prince Kyle has been kidnapped by Brie, the self-proclaimed Queen of Cheese. Dame Julia must cross the Royal Orchard, Honey Hollow, and the halls of Brie Keep to rescue him.\n\nMove  A / D      Jump  W / Space      Attack  J      Fire  H      Dodge  K      Jam Boost  L\n\nTip: enemies can be slain with your sword, or squashed by landing on top of them."

func _ready() -> void:
	Game.state_changed.connect(_on_state_changed)
	Game.dialogue_line_changed.connect(_on_dialogue_line)
	Game.dialogue_closed.connect(_on_dialogue_closed)
	overlay.action_pressed.connect(_on_overlay_action)
	_on_state_changed(Game.state)

func _physics_process(_delta: float) -> void:
	if Game.state != "playing" or current_level == null:
		return
	var move := 0
	if Input.is_action_pressed("move_left"):
		move -= 1
	if Input.is_action_pressed("move_right"):
		move += 1
	if Input.is_action_just_pressed("jump"):
		current_level.player.queue_jump()

	current_level.tick(
		move,
		Input.is_action_pressed("attack"),
		Input.is_action_pressed("fire"),
		Input.is_action_pressed("dodge"),
		Input.is_action_pressed("fart_boost")
	)

	hud.render_health(current_level.player.hp, current_level.player.max_hp)
	hud.render_ammo(current_level.player.ammo)
	hud.render_boost(current_level.player.has_fart_boost, current_level.player.fart_cooldown)

func _unhandled_input(event: InputEvent) -> void:
	if Game.state != "dialogue":
		return
	var advance := false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			advance = true
	elif event is InputEventMouseButton and event.pressed:
		advance = true
	if advance:
		Game.advance_dialogue()
		get_viewport().set_input_as_handled()

func _load_level(index: int) -> void:
	if current_level != null:
		current_level.queue_free()
		current_level = null
	Game.current_level_index = index
	current_level = LevelScene.instantiate() as Level
	level_container.add_child(current_level)
	current_level.player_died.connect(_on_player_died)
	current_level.level_completed.connect(_on_level_completed)
	current_level.victory_reached.connect(_on_victory_reached)
	current_level.boss_bar_changed.connect(hud.set_boss_bar)
	current_level.setup(index)

func _on_state_changed(new_state: String) -> void:
	match new_state:
		"start":
			overlay.configure("Dame Julia the Brave and the Quest for Prince Kyle", START_BODY, "Begin the Quest")
			dialogue_box.hide_box()
		"dialogue", "playing":
			overlay.hide_overlay()
		"levelcomplete":
			var lvl_name: String = Game.LEVELS[Game.current_level_index].name
			overlay.configure(lvl_name + " — Cleared!", _pending_outro, "Continue")
		"gameover":
			overlay.configure("Dame Julia Has Fallen...", "The quest ends here — but Dame Julia the Brave always rises again.", "Retry Level")
		"victory":
			overlay.configure("Victory!", "Brie has been defeated, Prince Kyle is safe, and the kingdom celebrates the wedding of Dame Julia and Prince Kyle!", "Play Again")

func _on_dialogue_line(speaker: String, text: String, portrait: String) -> void:
	dialogue_box.show_line(speaker, text, portrait)

func _on_dialogue_closed() -> void:
	dialogue_box.hide_box()

func _on_player_died() -> void:
	Game.set_state("gameover")

func _on_level_completed(outro_text: String) -> void:
	_pending_outro = outro_text
	Game.set_state("levelcomplete")

func _on_victory_reached() -> void:
	pass

func _on_overlay_action() -> void:
	match Game.state:
		"start":
			Game.reset_game()
			_load_level(0)
		"levelcomplete":
			if Game.current_level_index + 1 < Game.LEVELS.size():
				_load_level(Game.current_level_index + 1)
		"gameover":
			_load_level(Game.current_level_index)
		"victory":
			Game.reset_game()
			_load_level(0)
