extends Control
class_name HUD
## Hearts / ammo / boost / boss bar. Ported from renderHealth()/renderAmmo()/
## renderBoost()/updateBossBar() in index.html.

@onready var health_box: HBoxContainer = $HealthBox
@onready var ammo_label: Label = $AmmoLabel
@onready var boost_label: Label = $BoostLabel
@onready var boss_box: VBoxContainer = $BossBox
@onready var boss_name_label: Label = $BossBox/BossNameLabel
@onready var boss_bar: ProgressBar = $BossBox/BossBar

func _ready() -> void:
	boss_box.visible = false
	boost_label.visible = false

func render_health(hp: int, max_hp: int) -> void:
	for c in health_box.get_children():
		c.queue_free()
	for i in range(max_hp):
		var heart := ColorRect.new()
		heart.custom_minimum_size = Vector2(18, 16)
		heart.color = Color("#e0435c") if i < hp else Color("#3a2233")
		health_box.add_child(heart)

func render_ammo(ammo: int) -> void:
	ammo_label.text = "Arrows x%d" % ammo

func render_boost(has_boost: bool, cooldown: int) -> void:
	boost_label.visible = has_boost
	if not has_boost:
		return
	boost_label.text = "Jam Boost READY" if cooldown <= 0 else "Jam Boost %ds" % int(ceil(cooldown / 60.0))

func set_boss_bar(visible_: bool, boss_name: String, pct: float) -> void:
	boss_box.visible = visible_
	if visible_:
		boss_name_label.text = boss_name
		boss_bar.value = pct * 100.0
