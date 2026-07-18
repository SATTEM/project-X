class_name CardDisplay
extends Control

signal card_pressed(card: Card)

@export var background: TextureRect
@export var card_texture: TextureRect
@export var cost_label: Label
@export var name_label: Label
@export var description_label: Label
@export var visual_root: Control

var card: Card
var _visual_tween: Tween
var _hovered := false
var _motion_locked := false
var _click_enabled := true


func _ready() -> void:
	gui_input.connect(_on_CardDisplay_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_update_visual_pivot()
	resized.connect(_update_visual_pivot)


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
	description_label.text = card.card_description


func set_interactive(enabled: bool) -> void:
	_click_enabled = enabled
	mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


func set_click_enabled(enabled: bool) -> void:
	_click_enabled = enabled
	mouse_filter = Control.MOUSE_FILTER_STOP


func play_draw_animation(global_origin: Vector2, delay: float = 0.0) -> void:
	## 从抽牌堆位置飞入手牌。只操作显示节点，不参与牌堆逻辑。
	if not visual_root or not is_inside_tree():
		return
	_kill_visual_tween()
	_motion_locked = true
	z_index = 35
	visual_root.position = global_origin - global_position - size * 0.5
	visual_root.scale = Vector2(0.68, 0.68)
	visual_root.rotation = -0.09
	visual_root.self_modulate = Color(0.72, 0.92, 1.0, 0.18)

	_visual_tween = create_tween().set_parallel(true)
	_visual_tween.set_trans(Tween.TRANS_QUART)
	_visual_tween.set_ease(Tween.EASE_OUT)
	_visual_tween.tween_property(visual_root, "position", Vector2.ZERO, 0.34).set_delay(delay)
	_visual_tween.tween_property(visual_root, "scale", Vector2.ONE, 0.34).set_delay(delay)
	_visual_tween.tween_property(visual_root, "rotation", 0.0, 0.34).set_delay(delay)
	_visual_tween.tween_property(visual_root, "self_modulate", Color.WHITE, 0.25).set_delay(delay)
	_visual_tween.tween_callback(_finish_motion).set_delay(delay + 0.34)


func play_discard_animation(global_target: Vector2, delay: float = 0.0) -> void:
	## 用于独立的视觉副本：缩小、旋转并飞向弃牌堆。
	if not visual_root or not is_inside_tree():
		queue_free()
		return
	_kill_visual_tween()
	_motion_locked = true
	set_interactive(false)
	z_index = 90
	var target_position := global_target - size * 0.5

	_visual_tween = create_tween().set_parallel(true)
	_visual_tween.set_trans(Tween.TRANS_QUAD)
	_visual_tween.set_ease(Tween.EASE_IN)
	_visual_tween.tween_property(self, "global_position", target_position, 0.30).set_delay(delay)
	_visual_tween.tween_property(visual_root, "scale", Vector2(0.34, 0.34), 0.30).set_delay(delay)
	_visual_tween.tween_property(visual_root, "rotation", 0.24, 0.30).set_delay(delay)
	_visual_tween.tween_property(visual_root, "self_modulate:a", 0.0, 0.18).set_delay(delay + 0.12)
	_visual_tween.tween_callback(queue_free).set_delay(delay + 0.31)


func play_card_animation(global_target: Vector2) -> void:
	## 用于独立的视觉副本：抬起卡牌，冲向目标后淡出。
	if not visual_root or not is_inside_tree():
		queue_free()
		return
	_kill_visual_tween()
	_motion_locked = true
	set_interactive(false)
	z_index = 95
	var target_position := global_target - size * 0.5

	_visual_tween = create_tween().set_parallel(true)
	_visual_tween.set_trans(Tween.TRANS_CUBIC)
	_visual_tween.set_ease(Tween.EASE_OUT)
	_visual_tween.tween_property(visual_root, "position:y", -26.0, 0.10)
	_visual_tween.tween_property(visual_root, "scale", Vector2(1.10, 1.10), 0.10)
	_visual_tween.tween_property(self, "global_position", target_position, 0.28).set_delay(0.08)
	_visual_tween.tween_property(visual_root, "scale", Vector2(0.70, 0.70), 0.28).set_delay(0.08)
	_visual_tween.tween_property(visual_root, "rotation", 0.07, 0.28).set_delay(0.08)
	_visual_tween.tween_property(visual_root, "self_modulate:a", 0.0, 0.14).set_delay(0.23)
	_visual_tween.tween_callback(queue_free).set_delay(0.38)


func _on_mouse_entered() -> void:
	_hovered = true
	if not _motion_locked and mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_tween_hover(true)


func _on_mouse_exited() -> void:
	_hovered = false
	if not _motion_locked:
		_tween_hover(false)


func _tween_hover(hovered: bool) -> void:
	if not visual_root:
		return
	_kill_visual_tween()
	z_index = 40 if hovered else 0
	_visual_tween = create_tween().set_parallel(true)
	_visual_tween.set_trans(Tween.TRANS_QUAD)
	_visual_tween.set_ease(Tween.EASE_OUT)
	_visual_tween.tween_property(visual_root, "position", Vector2(0.0, -20.0) if hovered else Vector2.ZERO, 0.13)
	_visual_tween.tween_property(visual_root, "scale", Vector2(1.07, 1.07) if hovered else Vector2.ONE, 0.13)
	_visual_tween.tween_property(visual_root, "rotation", -0.012 if hovered else 0.0, 0.13)


func _finish_motion() -> void:
	_motion_locked = false
	z_index = 0
	if _hovered and mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_tween_hover(true)


func _update_visual_pivot() -> void:
	if visual_root:
		visual_root.pivot_offset = size * 0.5


func _kill_visual_tween() -> void:
	if _visual_tween and _visual_tween.is_valid():
		_visual_tween.kill()



func _on_CardDisplay_gui_input(event: InputEvent) -> void:
	if _click_enabled and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 发射信号，由 BattleUI 决定是直接打出还是进入目标选择模式
		card_pressed.emit(card)
