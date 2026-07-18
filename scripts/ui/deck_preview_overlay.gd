class_name DeckPreviewOverlay
extends Control

@export var card_display_scene: PackedScene

@onready var _title_label: Label = $Panel/Margin/VBox/Header/TitleLabel
@onready var _count_label: Label = $Panel/Margin/VBox/Header/CountLabel
@onready var _cards_grid: GridContainer = $Panel/Margin/VBox/CardScroll/CardsGrid
@onready var _empty_label: Label = $Panel/Margin/VBox/EmptyLabel
@onready var _close_button: Button = $Panel/Margin/VBox/Header/CloseButton
@onready var _dismiss_button: Button = $DismissButton
@onready var _dimmer: ColorRect = $Dimmer
@onready var _panel: PanelContainer = $Panel


func _ready() -> void:
	_layout_overlay()
	resized.connect(_layout_overlay)
	_close_button.pressed.connect(close)
	_dismiss_button.pressed.connect(close)
	call_deferred("_layout_overlay")


func show_pile(title: String, cards: Array) -> void:
	_title_label.text = title
	_count_label.text = "共 %d 张" % cards.size()
	_empty_label.visible = cards.is_empty()
	_cards_grid.visible = not cards.is_empty()
	for child in _cards_grid.get_children():
		child.queue_free()
	var preview_cards := cards.duplicate()
	preview_cards.shuffle()
	for card in preview_cards:
		if not card is Card or not is_instance_valid(card):
			continue
		var card_display := card_display_scene.instantiate() as CardDisplay
		card_display.set_card(card)
		card_display.set_click_enabled(false)
		_cards_grid.add_child(card_display)


func close() -> void:
	queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _layout_overlay() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	_dimmer.position = Vector2.ZERO
	_dimmer.size = size
	_dismiss_button.position = Vector2.ZERO
	_dismiss_button.size = size
	_panel.position = Vector2(size.x * 0.12, size.y * 0.10)
	_panel.size = Vector2(size.x * 0.76, size.y * 0.76)
