class_name CharacterWorldUI
extends Control

@export var body_sprite: Sprite2D
@export var health_bar_bg: ColorRect
@export var health_bar_fill: ColorRect
@export var block_container: Control
@export var block_icon: TextureRect
@export var block_label: Label
@export var intent_container: Control
@export var intent_icon: TextureRect
@export var intent_label: Label

var _character: Character = null


func setup(character: Character) -> void:
	_character = character

	# ---------- 立绘 ----------
	var texture = character.body_texture          # 需要 Character 提供这个 getter
	if texture:
		body_sprite.texture = texture
		var display_size = character.display_size
		var tex_size = texture.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			body_sprite.scale = display_size / tex_size
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
	var bar_height = 12
	health_bar_bg.color = Color(0.2, 0.2, 0.2, 0.5)
	health_bar_bg.size = Vector2(bar_width, bar_height)
	health_bar_bg.position = Vector2(-bar_width / 2.0, actual_size.y / 2.0 + 20)

	health_bar_fill.color = Color.RED
	health_bar_fill.size = Vector2(bar_width, bar_height)
	health_bar_fill.position = health_bar_bg.position

	# ---------- 格挡（血条下方） ----------
	block_container.position = health_bar_bg.position + Vector2(0, bar_height + 4)
	block_icon.custom_minimum_size = Vector2(24, 24)
	block_label.add_theme_font_size_override("font_size", 14)

	# ---------- 信号 ----------
	character.health_changed.connect(_on_health_changed)
	character.block_changed.connect(_on_block_changed)
	character.damage_display.connect(play_hit_animation)
	
	if character is Monster:
		character.intent_changed.connect(_on_intent_changed)
	else:
		intent_container.visible = false
	
	_on_health_changed(character, character.health)
	_on_block_changed(character, character.block)


func _on_health_changed(_char: Character, new_health: int) -> void:
	health_bar_fill.size.x = health_bar_bg.size.x * (float(new_health) / float(_char.health_max))


func _on_block_changed(_char: Character, new_block: int) -> void:
	block_label.text = str(new_block)
	block_container.visible = new_block > 0


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
