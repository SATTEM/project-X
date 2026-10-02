class_name HandLimitBubble
extends Control

@onready var _message_label: Label = $Panel/Margin/Message


func show_at_global(anchor_position: Vector2, overflow_count: int) -> void:
	if overflow_count <= 1:
		_message_label.text = "我的手牌已经满了！\n多抽的牌进入了弃牌堆"
	else:
		_message_label.text = "我的手牌已经满了！\n多抽的 %d 张牌进入了弃牌堆" % overflow_count

	global_position = anchor_position + Vector2(-185.0, -235.0)
	pivot_offset = size * 0.5
	modulate.a = 0.0
	scale = Vector2(0.86, 0.86)

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.16)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18)
	tween.tween_property(self, "position:y", position.y - 8.0, 1.80)
	tween.tween_property(self, "modulate:a", 0.0, 0.25).set_delay(1.55)
	tween.tween_callback(queue_free).set_delay(1.82)
