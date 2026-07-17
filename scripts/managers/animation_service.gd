extends Node
## 负责所有战斗视觉特效

var _canvas_layer: CanvasLayer
var _floating_text_sequences: Dictionary[int, int] = {}


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
	# 连击会在同一帧产生多个数字；使用四条错位轨道避免文本完全重叠。
	var character_id := character.get_instance_id()
	var sequence: int = _floating_text_sequences.get(character_id, 0)
	_floating_text_sequences[character_id] = sequence + 1
	var lane := sequence % 4
	var lane_offsets: Array[float] = [-42.0, -14.0, 14.0, 42.0]
	var lane_x := lane_offsets[lane]
	label.position = character.global_position + Vector2(lane_x, -80.0 - lane * 14.0)
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
	## 高光选择攻击对象
	var node_to_modulate = _get_display_node(character)
	if node_to_modulate:
		node_to_modulate.modulate = Color.YELLOW

func remove_highlight(character: Character) -> void:
	var node_to_modulate = _get_display_node(character)
	if node_to_modulate:
		node_to_modulate.modulate = Color.WHITE

func _get_display_node(character: Character) -> Node2D:
	# 优先使用怪物自己的 display_node
	if character is Monster and character.display_node:
		return character.display_node
	# 否则使用 body_sprite
	if character.world_ui and character.world_ui.body_sprite:
		return character.world_ui.body_sprite
	return null
