extends Control
class_name GameOverlay
## Single reusable full-screen overlay for the start / level-complete /
## game-over / victory states (only one is ever shown at a time, so the
## original's four separate <div> overlays collapse into one here).

signal action_pressed

@onready var title_label: Label = $Panel/VBox/Title
@onready var body_label: Label = $Panel/VBox/Body
@onready var button: Button = $Panel/VBox/Button

func _ready() -> void:
	button.pressed.connect(func(): action_pressed.emit())
	visible = false

func configure(title: String, body: String, button_text: String) -> void:
	title_label.text = title
	body_label.text = body
	button.text = button_text
	visible = true

func hide_overlay() -> void:
	visible = false
