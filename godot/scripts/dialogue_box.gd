extends Control
class_name DialogueBox

@onready var portrait_rect: TextureRect = $Panel/HBox/Portrait
@onready var name_label: Label = $Panel/HBox/TextBox/Name
@onready var line_label: Label = $Panel/HBox/TextBox/Line

func _ready() -> void:
	visible = false

func show_line(speaker: String, text: String, portrait_key: String) -> void:
	visible = true
	name_label.text = speaker
	line_label.text = text
	var path: String = Game.PORTRAITS.get(portrait_key, "")
	if path != "":
		portrait_rect.texture = load(path)

func hide_box() -> void:
	visible = false
