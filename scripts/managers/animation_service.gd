extends Node
## 负责所有战斗视觉特效

var _canvas_layer: CanvasLayer


func _ready() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 128
	add_child(_canvas_layer)
	# 接受转发信号并处理
	BattleManager.damage_display_requested.connect(_on_damage_display)
	BattleManager.block_display_requested.connect(_on_block_display)
	BattleManager.heal_display_requested.connect(_on_heal_display)


func _on_damage_display(character: Character, amount: int) -> void:
	_show_floating_text(character, "-%d" % amount, Color.RED)


func _on_block_display(character: Character, amount: int) -> void:
	_show_floating_text(character, "+%d Block" % amount, Color.CYAN)


func _on_heal_display(character: Character, amount: int) -> void:
	_show_floating_text(character, "+%d HP" % amount, Color.GREEN)


func _show_floating_text(character: Character, text: String, color: Color) -> void:
	## 显示浮动数字
	if not _canvas_layer:
		return

	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", Settings.ui_design_font_size)
	label.position = character.global_position + Vector2(0, -80)
	# 确保完全不透明
	label.modulate.a = 1.0
	_canvas_layer.add_child(label)

	var tween = create_tween()
	tween.set_parallel()
	# 上浮
	tween.tween_property(label, "position:y", label.position.y - Settings.ui_design_float_offset, Settings.ui_design_float_duration)
	# 淡出
	tween.tween_property(label, "modulate:a", 0.0, Settings.ui_design_float_duration)
	# 动画结束后清理
	tween.tween_callback(label.queue_free).set_delay(Settings.ui_design_float_duration)


func add_highlight(character: Character) -> void:
	## 给角色添加高光
	var sprite = character.world_ui.body_sprite
	sprite.modulate = Color.YELLOW


func remove_highlight(character: Character) -> void:
	## 消除高光
	var sprite = character.world_ui.body_sprite
	sprite.modulate = Color.WHITE
