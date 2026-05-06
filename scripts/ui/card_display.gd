class_name CardDisplay
extends Control

signal card_pressed(card: Card)

@export var background: TextureRect
@export var cost_label: Label
@export var name_label: Label
@export var description_label: Label

var card: Card


func _ready() -> void:
	connect("gui_input", _on_CardDisplay_gui_input)


func set_card(new_card: Card) -> void:
	card = new_card
	background.texture = card.card_resource.texture
	cost_label.text = str(card.cost)
	name_label.text = card.card_name
	# 提取效果名称
	var effect_names = []
	for effect in card.effects:
		effect_names.append(effect.effect_name)
	description_label.text = ", ".join(effect_names)



func _on_CardDisplay_gui_input(event: InputEvent) -> void:
	## 点击事件
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_pressed.emit(card)
