extends CanvasLayer

signal reward_selected(card_id: String) 

@export var card_display_scene: PackedScene

@onready var cards_container = $Panel/CardsContainer
@onready var skip_button = $Panel/SkipButton

var _reward_card_ids: Array[String] = []
var _player_state: PlayerState
var _selected: bool = false


func setup_rewards_and_wait(reward_ids: Array[String], player_state: PlayerState) -> Signal:
	_reward_card_ids = reward_ids
	_player_state = player_state
	skip_button.pressed.connect(_on_skip_button_pressed)
	_display_cards()
	return reward_selected


func _display_cards() -> void:
	for child in cards_container.get_children():
		if is_instance_valid(child):
			child.queue_free()
	
	var display_ids = _reward_card_ids.slice(0, 3)
	
	for card_id in display_ids:
		var card = CardLibrary.create_card(card_id)
		if not card:
			continue
		var card_display = card_display_scene.instantiate()
		card_display.set_card(card)
		card_display.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_card_selected(card_id, card_display)
		)
		
		cards_container.add_child(card_display)
		card.queue_free()


func _on_card_selected(card_id: String, card_display: Control) -> void:
	if _selected:
		return
	_selected = true
	
	# 选中的卡牌淡出
	var tween1 = create_tween()
	tween1.tween_property(card_display, "modulate:a", 0.0, 0.4)
	await tween1.finished
	if is_instance_valid(card_display):
		card_display.queue_free()
	
	await get_tree().create_timer(0.2).timeout
	
	# 其他卡牌淡出
	var tween2 = create_tween()
	tween2.set_parallel(true)
	for child in cards_container.get_children():
		if child is Control:
			tween2.tween_property(child, "modulate:a", 0.0, 0.3)
	await tween2.finished
	for child in cards_container.get_children():
		if child is Control and is_instance_valid(child):
			child.queue_free()
	
	# 发出选中的卡牌 ID
	reward_selected.emit(card_id)
	queue_free()


func _on_skip_button_pressed() -> void:
	if _selected:
		return
	_selected = true
	
	print("跳过奖励界面")
	var tween = create_tween()
	tween.set_parallel(true)
	for child in cards_container.get_children():
		if child is Control:
			tween.tween_property(child, "modulate:a", 0.0, 0.4)
	await tween.finished
	for child in cards_container.get_children():
		if child is Control and is_instance_valid(child):
			child.queue_free()
	
	# 跳过时发出空字符串
	reward_selected.emit("")
	queue_free()
