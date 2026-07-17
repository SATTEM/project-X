class_name CharacterWorldUI
extends Control

const HEALTH_FILL_COLOR := Color(0.86, 0.14, 0.18, 1.0)

@export var body_sprite: Sprite2D
@export var health_bar_bg: ColorRect
@export var health_bar_fill: ColorRect
@export var health_frame: Panel
@export var block_frame: Panel
@export var block_container: Control
@export var block_icon: TextureRect
@export var block_label: Label
@export var intent_container: Control
@export var intent_icon: TextureRect
@export var intent_label: Label
@export var energy_container: Control

var _character: Character = null
var energy_displays: Dictionary = {}


func setup(character: Character) -> void:
	_character = character

	# ---------- 立绘 ----------
	var texture = character.body_texture          # 需要 Character 提供这个 getter
	if texture:
		body_sprite.texture = texture
		var display_size = character.display_size
		var universal_shrink_factor = 0.7  #整体缩小系数 
		var tex_size = texture.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			body_sprite.scale = (display_size / tex_size) * universal_shrink_factor
	# 将 body_sprite 放在 WorldUI 原点 (0,0)，立绘居中
	body_sprite.position = Vector2.ZERO

	# ---------- 意图（头顶） ----------
	var actual_size = body_sprite.texture.get_size() * body_sprite.scale
	intent_container.position = Vector2(0, -actual_size.y / 2.0 - 40)
	var intent_size = max(actual_size.x * 0.25, 48)
	intent_icon.custom_minimum_size = Vector2(intent_size, intent_size)
	intent_icon.expand = true
	intent_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# ---------- 血条（脚下） ----------
	var bar_width = actual_size.x * 0.8
	var bar_height = 14
	health_bar_bg.color = Color(0.025, 0.07, 0.09, 0.94)
	health_bar_bg.size = Vector2(bar_width, bar_height)
	health_bar_bg.position = Vector2(-bar_width / 2.0, actual_size.y / 2.0 + 20)

	health_bar_fill.color = HEALTH_FILL_COLOR
	health_bar_fill.size = Vector2(bar_width, bar_height)
	health_bar_fill.position = health_bar_bg.position

	# ---------- 格挡（血条下方） ----------
	health_frame.position = health_bar_bg.position - Vector2(3, 3)
	health_frame.size = health_bar_bg.size + Vector2(6, 6)
	block_frame.position = health_frame.position
	block_frame.size = health_frame.size
	block_container.position = health_bar_bg.position + Vector2(-52, (bar_height - 40) * 0.5)
	block_icon.custom_minimum_size = Vector2(40, 40)
	block_label.add_theme_font_size_override("font_size", 18)

	if character is Monster:
		_build_monster_energy_displays()
		_update_monster_energy_display()
	else:
		energy_container.visible = false

	# ---------- 信号 ----------
	if not character.health_changed.is_connected(_on_health_changed):
		character.health_changed.connect(_on_health_changed)
	if not character.block_changed.is_connected(_on_block_changed):
		character.block_changed.connect(_on_block_changed)
	if not character.damage_display.is_connected(play_hit_animation):
		character.damage_display.connect(play_hit_animation)
	
	if character is Monster:
		if not character.intent_changed.is_connected(_on_intent_changed):
			character.intent_changed.connect(_on_intent_changed)
		if not character.energy_changed.is_connected(_update_monster_energy_display):
			character.energy_changed.connect(_update_monster_energy_display)
	else:
		intent_container.visible = false
	
	_on_health_changed(character, character.health)
	_on_block_changed(character, character.block)


func _on_health_changed(_char: Character, new_health: int) -> void:
	health_bar_fill.size.x = health_bar_bg.size.x * (float(new_health) / float(_char.health_max))


func _on_block_changed(_char: Character, new_block: int) -> void:
	health_bar_fill.color = HEALTH_FILL_COLOR
	block_label.text = str(new_block)
	var has_block := new_block > 0
	block_container.visible = has_block
	block_frame.visible = has_block


func _on_intent_changed(type: String, value: int) -> void:
	intent_label.text = "%s %d" % [type, value]
	intent_container.visible = true


func play_hit_animation(__character: Character, _amount: int) -> void:
	if not body_sprite:
		return
	var tween = create_tween().set_parallel(true)
	tween.tween_property(body_sprite, "modulate", Color.RED, 0.05)
	tween.tween_property(body_sprite, "modulate", Color.WHITE, 0.15).set_delay(0.05)
	var orig = position
	tween.tween_property(self, "position", orig + Vector2(8, 0), 0.04)
	tween.tween_property(self, "position", orig - Vector2(8, 0), 0.04).set_delay(0.04)
	tween.tween_property(self, "position", orig, 0.08).set_delay(0.08)


func _build_monster_energy_displays() -> void:
	# 清除旧子节点
	for child in energy_container.get_children():
		child.queue_free()
	energy_displays.clear()

	var monster = _character as Monster
	var element_icons = GlobalEnums.ElementIcon

	var spacing = 40
	var total_width = monster.energy_slots.size() * spacing
	var start_x = -total_width / 2.0 + 65

	var i = 0
	for element in monster.energy_slots.keys():
		var icon = TextureRect.new()
		icon.texture = element_icons.get(element)
		icon.expand = true
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(16, 16)
		icon.position = Vector2(start_x + i * spacing, 0)
		energy_container.add_child(icon)

		var label = Label.new()
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.position = icon.position + Vector2(16, 2)
		energy_container.add_child(label)

		energy_displays[element] = { "icon": icon, "label": label }
		i += 1

	# 容器位置：血条上方，居中
	energy_container.position = Vector2(-total_width / 2.0, health_bar_bg.position.y - 20)


func _update_monster_energy_display() -> void:
	var monster = _character as Monster
	for element in monster.energy_slots:
		var data = energy_displays.get(element)
		if data:
			var current = monster.energy_slots[element]
			var max_val = monster.energy_slots_max.get(element, 0)
			data["label"].text = "%d/%d" % [current, max_val]
			# 可调整图标透明度表示当前是否有能量
			data["icon"].modulate.a = 1.0 if current > 0 else 0.3
