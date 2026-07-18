extends Node
## Global state machine, persistent player stats, and all level/dialogue data.
## Ported directly from the original index.html canvas game.

signal state_changed(new_state: String)
signal dialogue_line_changed(speaker: String, text: String, portrait: String)
signal dialogue_closed

const GROUND_Y := 440
const VIEW_W := 960
const VIEW_H := 540

const PORTRAITS := {
	"julia": "res://assets/portraits/julia.svg",
	"kyle": "res://assets/portraits/kyle.svg",
	"apple": "res://assets/portraits/apple.svg",
	"honey": "res://assets/portraits/honey.svg",
	"brie": "res://assets/portraits/brie.svg",
	"wedding": "res://assets/portraits/wedding.svg",
}

# start | playing | dialogue | levelcomplete | gameover | victory
var state: String = "start"
var current_level_index: int = 0

# Persists across level loads (matches resetPlayerForLevel not touching these).
var player_max_hp: int = 6
var player_has_fart_boost: bool = false

var _dialogue_queue: Array = []
var _dialogue_callback: Callable = Callable()
var _prev_state_before_dialogue: String = "playing"

func _ground(x: int, w: int, color: String = "#5b3a21", top: String = "#7ea24a") -> Dictionary:
	return {"x": x, "y": GROUND_Y, "w": w, "h": 300, "color": color, "top": top}

func _plat(x: int, y: int, w: int, h: int, color: String = "#7a5a34", top: String = "#8fae5c") -> Dictionary:
	return {"x": x, "y": y, "w": w, "h": h, "color": color, "top": top}

func reset_game() -> void:
	current_level_index = 0
	player_max_hp = 6
	player_has_fart_boost = false

func set_state(s: String) -> void:
	state = s
	state_changed.emit(s)

func start_dialogue(lines: Array, callback: Callable = Callable()) -> void:
	if lines.is_empty():
		if callback.is_valid():
			callback.call()
		return
	_dialogue_queue = lines.duplicate(true)
	_dialogue_callback = callback
	_prev_state_before_dialogue = state
	set_state("dialogue")
	_show_next_line()

func advance_dialogue() -> void:
	if state != "dialogue":
		return
	_show_next_line()

func _show_next_line() -> void:
	if _dialogue_queue.is_empty():
		var next_state: String = _prev_state_before_dialogue
		if next_state == "dialogue" or next_state == "start":
			next_state = "playing"
		set_state(next_state)
		dialogue_closed.emit()
		var cb := _dialogue_callback
		_dialogue_callback = Callable()
		if cb.is_valid():
			cb.call()
		return
	var line: Dictionary = _dialogue_queue.pop_front()
	dialogue_line_changed.emit(line.get("name", ""), line.get("text", ""), line.get("portrait", ""))

# ================= SHARED (LEVEL-INDEPENDENT) DIALOGUE =================
# These mirror jebIntroDialogue/jebFleeSequence/friarSlideDialogue/princeKyleDialogue/
# kingsFinaleDialogue/friarDialogue in the original script — same text is reused for
# both boss-arena levels, exactly like the source.

func brie_intro_lines() -> Array:
	return [
		{"name": "Brie", "portrait": "brie", "text": "So, Dame Julia finally reaches my caverns. I expected someone taller."},
		{"name": "Dame Julia", "portrait": "julia", "text": "I have come for Prince Kyle. Release him."},
		{"name": "Dame Julia", "portrait": "julia", "text": "(Those hanging pantry stones look loose. A well-placed shot could bring them down.)"},
		{"name": "Brie", "portrait": "brie", "text": "Prince Kyle will stand beside me when every meal in the kingdom belongs to Brie!"},
	]

func brie_flee_lines() -> Array:
	return [
		{"name": "Brie", "portrait": "brie", "text": "Impossible! You have cracked my outer rind, but the heart of Brie remains undefeated!"},
		{"name": "Brie", "portrait": "brie", "text": "I am taking Prince Kyle to the throne room. Follow me if you dare!"},
		{"name": "Dame Julia", "portrait": "julia", "text": "Run while you can, Brie. This rescue is not over."},
	]

func friar_slide_lines() -> Array:
	return [
		{"name": "Prince Kyle", "portrait": "kyle", "text": "Julia! I found a hidden speaking tube. Brie is moving me to the throne room."},
		{"name": "Prince Kyle", "portrait": "kyle", "text": "There is a pantry chute through the wall. It leads deeper into the keep."},
		{"name": "Prince Kyle", "portrait": "kyle", "text": "I also pushed a jar of royal strawberry jam into the chute. It should restore your strength."},
		{"name": "Dame Julia", "portrait": "julia", "text": "Hold on, Kyle. I will finish this."},
	]

func prince_kyle_lines() -> Array:
	return [
		{"name": "Prince Kyle", "portrait": "kyle", "text": "Julia! You crossed the entire kingdom for me."},
		{"name": "Dame Julia", "portrait": "julia", "text": "Of course I did. No enchanted fruit, honey jar, or wheel of cheese was going to keep us apart."},
		{"name": "Prince Kyle", "portrait": "kyle", "text": "Then let us return home. There is one question I have been waiting to ask."},
		{"name": "Prince Kyle", "portrait": "kyle", "text": "Dame Julia the Brave, will you marry me?"},
		{"name": "Dame Julia", "portrait": "julia", "text": "Yes, Prince Kyle. Absolutely yes."},
	]

func kings_finale_lines() -> Array:
	return [
		{"name": "Narrator", "portrait": "julia", "text": "The kingdom gathered beneath banners of gold, rose, and royal blue."},
		{"name": "Prince Kyle", "portrait": "kyle", "text": "Before this kingdom, I choose Dame Julia as my partner, my champion, and my greatest adventure."},
		{"name": "Dame Julia", "portrait": "julia", "text": "And I choose Prince Kyle—with or without an army of angry food chasing him."},
		{"name": "Narrator", "portrait": "wedding", "text": "Dame Julia and Prince Kyle were married as bells rang across the kingdom. Even Sir Apple and Baron Honey attended—under close supervision."},
	]

func friar_lines() -> Array:
	return [
		{"name": "Prince Kyle", "portrait": "kyle", "text": "Julia, can you hear me through the enchanted crest?"},
		{"name": "Prince Kyle", "portrait": "kyle", "text": "Brie's servants are everywhere. The small ones change with each territory—orchardlings, honey blobs, then rindlings."},
		{"name": "Dame Julia", "portrait": "julia", "text": "I hear you. Stay brave. I am on my way."},
		{"name": "Prince Kyle", "portrait": "kyle", "text": "Always."},
	]

# ================= LEVELS =================
var LEVELS: Array = []

func _ready() -> void:
	LEVELS = _build_levels()

func _build_levels() -> Array:
	return [
		{
			"name": "The Royal Orchard",
			"width": 3400, "enemy_hp": 1, "friar_x": 1650,
			"bg": "#87ceeb", "bg_far": "#c9e8f5", "theme": "orchard", "enemy_kind": "apple",
			"platforms": [
				_ground(0, 900), _ground(980, 500), _ground(1560, 500), _ground(2240, 400), _ground(2740, 660),
				_plat(420, 330, 140, 24), _plat(650, 260, 120, 24), _plat(1080, 350, 110, 24),
				_plat(1720, 320, 130, 24), _plat(1950, 250, 120, 24), _plat(2280, 330, 110, 22), _plat(2450, 270, 110, 22),
			],
			"pits": [
				{"x": 900, "y": GROUND_Y, "w": 80, "h": 300}, {"x": 1480, "y": GROUND_Y, "w": 80, "h": 300},
				{"x": 2060, "y": GROUND_Y, "w": 180, "h": 300}, {"x": 2640, "y": GROUND_Y, "w": 100, "h": 300},
			],
			"spikes": [
				{"x": 2550, "y": GROUND_Y - 14, "w": 50, "h": 14}, {"x": 1105, "y": 350 - 14, "w": 50, "h": 14},
				{"x": 1975, "y": 250 - 14, "w": 50, "h": 14},
			],
			"moving_platforms": [
				{"x": 2150, "y": GROUND_Y - 40, "base_x": 2150.0, "base_y": GROUND_Y - 40.0, "w": 70, "h": 18, "axis": "x", "range": 40, "speed": 1.1, "phase": 0, "color": "#c9a227"},
			],
			"decor": [
				{"type": "bush", "x": 200, "scale": 1.0}, {"type": "rock", "x": 760, "scale": 1.1},
				{"type": "bush", "x": 1150, "scale": 0.9}, {"type": "rock", "x": 1650, "scale": 1.0},
				{"type": "bush", "x": 2320, "scale": 1.0}, {"type": "rock", "x": 2900, "scale": 1.2},
				{"type": "bush", "x": 3200, "scale": 1.0},
			],
			"enemies": [
				{"x": 500, "min": 420, "max": 700}, {"x": 1020, "min": 990, "max": 1150},
				{"x": 1100, "min": 1000, "max": 1300}, {"x": 1750, "min": 1620, "max": 1900},
				{"x": 2350, "min": 2260, "max": 2600}, {"x": 2850, "min": 2760, "max": 3050},
			],
			"flag_x": 3360,
			"has_mini_boss": true, "mini_boss_name": "Sir Apple", "mini_boss_kind": "apple",
			"mini_boss_hp": 6, "mini_boss_tie": "#8a1f2a",
			"mini_boss_intro": [
				{"name": "Sir Apple", "portrait": "apple", "text": "Halt! No knight passes through my orchard while I still have a stem to stand on."},
				{"name": "Dame Julia", "portrait": "julia", "text": "Stand aside, Sir Apple. Prince Kyle is waiting for me."},
				{"name": "Sir Apple", "portrait": "apple", "text": "Then prepare to be pressed into cider!"},
			],
			"kings_congrats": [
				{"name": "Dame Julia", "portrait": "julia", "text": "One villain down. The trail leads toward Honey Hollow."},
				{"name": "Prince Kyle", "portrait": "kyle", "text": "Julia... if you can hear me, please hurry. Brie is preparing something called a royal cheese ceremony."},
			],
			"intro": [
				{"name": "Prince Kyle", "portrait": "kyle", "text": "Julia! Brie and her food fiends have taken me to her fortress!"},
				{"name": "Dame Julia", "portrait": "julia", "text": "Hold on, Kyle. I will cross every orchard, hollow, and cheese cellar in the kingdom to reach you."},
				{"name": "Prince Kyle", "portrait": "kyle", "text": "Be careful. Sir Apple guards the road, and his orchardlings attack anything that is not fruit."},
				{"name": "Dame Julia", "portrait": "julia", "text": "Then I will give them a lesson in proper knightly nutrition."},
			],
			"outro": "Sir Apple has fallen. The sticky road to Honey Hollow lies ahead.",
		},
		{
			"name": "Honey Hollow",
			"width": 3800, "enemy_hp": 2,
			"bg": "#2f4d3a", "bg_far": "#3f6b4d", "theme": "honey", "enemy_kind": "honey",
			"platforms": [
				_ground(0, 500), _ground(600, 300), _ground(1000, 250), _ground(1350, 350), _ground(1800, 300),
				_ground(2200, 300), _ground(2600, 300), _ground(3080, 720),
				_plat(300, 340, 130, 22), _plat(700, 260, 110, 22), _plat(950, 200, 100, 22), _plat(1270, 300, 110, 22),
				_plat(1600, 250, 130, 22), _plat(1980, 320, 110, 22), _plat(2650, 330, 110, 22), _plat(2820, 270, 110, 22),
			],
			"pits": [
				{"x": 500, "y": GROUND_Y, "w": 100, "h": 300}, {"x": 900, "y": GROUND_Y, "w": 100, "h": 300},
				{"x": 1250, "y": GROUND_Y, "w": 100, "h": 300}, {"x": 1700, "y": GROUND_Y, "w": 100, "h": 300},
				{"x": 2100, "y": GROUND_Y, "w": 100, "h": 300}, {"x": 2500, "y": GROUND_Y, "w": 100, "h": 300},
				{"x": 2900, "y": GROUND_Y, "w": 180, "h": 300},
			],
			"spikes": [
				{"x": 2300, "y": GROUND_Y - 14, "w": 50, "h": 14}, {"x": 1630, "y": 250 - 14, "w": 50, "h": 14},
				{"x": 2840, "y": 270 - 14, "w": 50, "h": 14},
			],
			"moving_platforms": [
				{"x": 2990, "y": GROUND_Y - 40, "base_x": 2990.0, "base_y": GROUND_Y - 40.0, "w": 80, "h": 18, "axis": "y", "range": 60, "speed": 1.3, "phase": 0, "color": "#6b8f4a"},
			],
			"decor": [
				{"type": "tree", "x": 250, "scale": 1.0}, {"type": "bush", "x": 800, "scale": 1.0},
				{"type": "tree", "x": 1300, "scale": 0.9}, {"type": "rock", "x": 1750, "scale": 1.0},
				{"type": "tree", "x": 2050, "scale": 1.1}, {"type": "bush", "x": 2450, "scale": 1.0},
				{"type": "tree", "x": 2750, "scale": 1.0}, {"type": "rock", "x": 3300, "scale": 1.2},
			],
			"enemies": [
				{"x": 350, "min": 60, "max": 480}, {"x": 630, "min": 610, "max": 760}, {"x": 750, "min": 620, "max": 870},
				{"x": 1080, "min": 1020, "max": 1220}, {"x": 1450, "min": 1370, "max": 1650}, {"x": 1900, "min": 1820, "max": 2070},
				{"x": 2320, "min": 2220, "max": 2470}, {"x": 2750, "min": 2620, "max": 2870}, {"x": 3200, "min": 3100, "max": 3400},
			],
			"flag_x": 3760,
			"has_mini_boss": true, "mini_boss_name": "Baron Honey", "mini_boss_kind": "honey",
			"mini_boss_hp": 7, "mini_boss_tie": "#5a2f8a",
			"mini_boss_intro": [
				{"name": "Baron Honey", "portrait": "honey", "text": "You have wandered into my hollow, Dame Julia. Every step from here will be slow, sticky, and regrettable."},
				{"name": "Dame Julia", "portrait": "julia", "text": "Release the road, Baron Honey."},
				{"name": "Baron Honey", "portrait": "honey", "text": "Never! My bees and honey blobs will keep you here forever!"},
			],
			"kings_congrats": [
				{"name": "Dame Julia", "portrait": "julia", "text": "Baron Honey is defeated. Brie Keep cannot be far now."},
				{"name": "Prince Kyle", "portrait": "kyle", "text": "I found a loose stone in my cell. I left my royal crest in the caverns below. Follow it."},
			],
			"intro": [
				{"name": "Dame Julia", "portrait": "julia", "text": "The air smells like flowers, bees, and an unreasonable amount of honey."},
			],
			"outro": "Honey Hollow is clear. Prince Kyle's trail leads underground.",
		},
		{
			"name": "The Cheese Caverns",
			"width": 2800, "enemy_hp": 3,
			"bg": "#241222", "bg_far": "#3a1c38", "theme": "cheese", "enemy_kind": "cheese",
			"platforms": [
				_ground(0, 500), _ground(650, 300), _ground(1100, 280), _ground(1550, 350), _ground(1900, 100),
				_ground(2000, 100), _ground(2250, 550),
				_plat(330, 330, 120, 22), _plat(720, 250, 110, 22), _plat(1000, 190, 100, 22),
				_plat(1350, 280, 110, 22), _plat(1700, 320, 120, 22),
			],
			"pits": [
				{"x": 500, "y": GROUND_Y, "w": 150, "h": 300, "lava": true}, {"x": 950, "y": GROUND_Y, "w": 150, "h": 300, "lava": true},
				{"x": 1380, "y": GROUND_Y, "w": 170, "h": 300, "lava": true}, {"x": 2100, "y": GROUND_Y, "w": 150, "h": 300, "lava": true},
			],
			"spikes": [
				{"x": 1015, "y": 190 - 14, "w": 50, "h": 14}, {"x": 1720, "y": 320 - 14, "w": 50, "h": 14},
			],
			"moving_platforms": [
				{"x": 2160, "y": GROUND_Y - 50, "base_x": 2160.0, "base_y": GROUND_Y - 50.0, "w": 80, "h": 18, "axis": "x", "range": 50, "speed": 1.2, "phase": 0, "color": "#8a5a3a"},
			],
			"decor": [
				{"type": "stalagmite", "x": 200, "scale": 1.0}, {"type": "bones", "x": 850, "scale": 1.0},
				{"type": "stalagmite", "x": 1250, "scale": 1.1}, {"type": "bones", "x": 1700, "scale": 1.0},
				{"type": "stalagmite", "x": 2350, "scale": 0.9}, {"type": "bones", "x": 2600, "scale": 1.0},
			],
			"enemies": [
				{"x": 380, "min": 60, "max": 480}, {"x": 780, "min": 660, "max": 930}, {"x": 1200, "min": 1110, "max": 1360},
				{"x": 1700, "min": 1560, "max": 1880}, {"x": 2050, "min": 2010, "max": 2090},
			],
			"flag_x": 2760,
			"intro": [
				{"name": "Dame Julia", "portrait": "julia", "text": "Cheese wedges, mold creatures, and claw marks. Brie has turned the caverns into her private pantry."},
			],
			"boss_arena": true, "jeb_flees_at_low_hp": true,
			"arena_rocks": [{"x": 2300}, {"x": 2450}, {"x": 2600}],
			"outro": "The wall's still smoking where the slide punched through. Down we go.",
		},
		{
			"name": "The Pantry Passage",
			"width": 3200, "enemy_hp": 4,
			"bg": "#2a0808", "bg_far": "#4a2015", "theme": "briekeep", "enemy_kind": "cheese",
			"platforms": [
				_ground(0, 500, "#2b1a1a", "#5a3020"), _ground(650, 300, "#2b1a1a", "#5a3020"),
				_ground(1100, 280, "#2b1a1a", "#5a3020"), _ground(1550, 350, "#2b1a1a", "#5a3020"),
				_ground(2080, 270, "#2b1a1a", "#5a3020"), _ground(2500, 700, "#2b1a1a", "#5a3020"),
				_plat(330, 330, 120, 22, "#5a5a62", "#8a8a92"), _plat(720, 250, 110, 22, "#5a5a62", "#8a8a92"),
				_plat(1150, 190, 100, 22, "#5a5a62", "#8a8a92"), _plat(1600, 280, 110, 22, "#5a5a62", "#8a8a92"),
				_plat(2150, 230, 110, 22, "#5a5a62", "#8a8a92"), _plat(2600, 300, 110, 22, "#5a5a62", "#8a8a92"),
			],
			"pits": [
				{"x": 500, "y": GROUND_Y, "w": 150, "h": 300, "lava": true}, {"x": 950, "y": GROUND_Y, "w": 150, "h": 300, "lava": true},
				{"x": 1380, "y": GROUND_Y, "w": 170, "h": 300, "lava": true}, {"x": 1900, "y": GROUND_Y, "w": 180, "h": 300, "lava": true},
				{"x": 2350, "y": GROUND_Y, "w": 150, "h": 300, "lava": true},
			],
			"spikes": [
				{"x": 1165, "y": 190 - 14, "w": 50, "h": 14}, {"x": 2620, "y": 300 - 14, "w": 50, "h": 14},
				{"x": 2750, "y": GROUND_Y - 14, "w": 50, "h": 14},
			],
			"moving_platforms": [
				{"x": 1990, "y": GROUND_Y - 45, "base_x": 1990.0, "base_y": GROUND_Y - 45.0, "w": 80, "h": 18, "axis": "x", "range": 45, "speed": 1.3, "phase": 0, "color": "#c0521c"},
			],
			"decor": [
				{"type": "shelf", "x": 200, "scale": 1.0}, {"type": "cart", "x": 800, "scale": 1.0},
				{"type": "sign", "x": 1250, "scale": 1.0}, {"type": "shelf", "x": 1700, "scale": 1.1},
				{"type": "cart", "x": 2200, "scale": 0.9}, {"type": "sign", "x": 2700, "scale": 1.0},
				{"type": "shelf", "x": 3000, "scale": 1.0},
			],
			"enemies": [
				{"x": 350, "min": 60, "max": 480}, {"x": 700, "min": 660, "max": 900}, {"x": 1150, "min": 1110, "max": 1350},
				{"x": 1650, "min": 1560, "max": 1870}, {"x": 2120, "min": 2090, "max": 2320}, {"x": 2550, "min": 2510, "max": 2700},
				{"x": 2900, "min": 2820, "max": 3100},
			],
			"flag_x": 3160,
			"intro": [
				{"name": "Dame Julia", "portrait": "julia", "text": "The pantry passage is guarded by Brie's rindlings. Kyle must be close."},
			],
			"outro": "The final gate to Brie Keep stands ahead.",
		},
		{
			"name": "Brie Keep",
			"width": 2800, "enemy_hp": 5,
			"bg": "#2a0808", "bg_far": "#4a2015", "theme": "briekeep", "enemy_kind": "cheese",
			"jeb_hp": 22, "jeb_action_cooldown": 65,
			"platforms": [
				_ground(0, 500, "#2b1a1a", "#5a3020"), _ground(650, 300, "#2b1a1a", "#5a3020"),
				_ground(1100, 280, "#2b1a1a", "#5a3020"), _ground(1550, 350, "#2b1a1a", "#5a3020"),
				_ground(1900, 100, "#2b1a1a", "#5a3020"), _ground(2000, 100, "#2b1a1a", "#5a3020"),
				_ground(2250, 550, "#2b1a1a", "#5a3020"),
				_plat(330, 330, 120, 22, "#5a5a62", "#8a8a92"), _plat(720, 250, 110, 22, "#5a5a62", "#8a8a92"),
				_plat(1000, 190, 100, 22, "#5a5a62", "#8a8a92"), _plat(1350, 280, 110, 22, "#5a5a62", "#8a8a92"),
				_plat(1700, 320, 120, 22, "#5a5a62", "#8a8a92"),
			],
			"pits": [
				{"x": 500, "y": GROUND_Y, "w": 150, "h": 300, "lava": true}, {"x": 950, "y": GROUND_Y, "w": 150, "h": 300, "lava": true},
				{"x": 1380, "y": GROUND_Y, "w": 170, "h": 300, "lava": true}, {"x": 2100, "y": GROUND_Y, "w": 150, "h": 300, "lava": true},
			],
			"spikes": [
				{"x": 1015, "y": 190 - 14, "w": 50, "h": 14}, {"x": 1720, "y": 320 - 14, "w": 50, "h": 14},
			],
			"moving_platforms": [
				{"x": 2160, "y": GROUND_Y - 50, "base_x": 2160.0, "base_y": GROUND_Y - 50.0, "w": 80, "h": 18, "axis": "x", "range": 50, "speed": 1.2, "phase": 0, "color": "#8a5a3a"},
			],
			"decor": [
				{"type": "shelf", "x": 200, "scale": 1.0}, {"type": "bones", "x": 850, "scale": 1.0},
				{"type": "cart", "x": 1250, "scale": 1.0}, {"type": "stalagmite", "x": 1700, "scale": 1.0},
				{"type": "sign", "x": 2350, "scale": 1.0}, {"type": "bones", "x": 2600, "scale": 1.0},
			],
			"enemies": [
				{"x": 380, "min": 60, "max": 480}, {"x": 780, "min": 660, "max": 930}, {"x": 1200, "min": 1110, "max": 1360},
				{"x": 1700, "min": 1560, "max": 1880}, {"x": 2050, "min": 2010, "max": 2090},
			],
			"flag_x": 2760,
			"intro": [
				{"name": "Dame Julia", "portrait": "julia", "text": "Brie Keep. At last. Kyle, I am coming."},
			],
			"boss_arena": true,
			"arena_rocks": [{"x": 2300}, {"x": 2450}, {"x": 2600}],
		},
	]
