class_name CardDisplay
extends Control

signal card_pressed(card: Card)

@export var background: TextureRect
@export var card_texture: TextureRect
@export var cost_label: Label
@export var name_label: Label
@export var description_label: Label

var card: Card


func _ready() -> void:
	connect("gui_input", _on_CardDisplay_gui_input)


func set_card(new_card: Card) -> void:
	card = new_card
	if card.effects.is_empty() and card.card_resource and card.card_resource.effect_resources:
		for effect_resource in card.card_resource.effect_resources:
			card.effects.append(effect_resource.duplicate(true))
	background.texture = card.card_resource.background_texture
	card_texture.texture = card.card_resource.texture
	cost_label.text = str(card.cost)
	name_label.text = card.card_name
	# 提取效果名称
	var effect_names = []
	for effect in card.effects:
		effect_names.append(effect.effect_name)
	description_label.text = ", ".join(effect_names)



func _on_CardDisplay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 发射信号，由 BattleUI 决定是直接打出还是进入目标选择模式
		card_pressed.emit(card)
