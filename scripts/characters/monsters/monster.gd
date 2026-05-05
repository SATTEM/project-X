class_name Monster
extends Character

signal intent_changed(type: String, value: int)

var intent_cards: Array[Card] = []
var intent_type: String = ""
var intent_value: int = 0
var exist_turn: int = 0
var energy_slots: Dictionary[GlobalEnums.Element, int] = {GlobalEnums.Element.WATER: 1}
var energy_slots_max: Dictionary[GlobalEnums.Element, int]:
	get:
		return monster_resource.energy_slots_max
var monster_resource: MonsterResource
var monster_texture: Texture2D:
	get:
		return monster_resource.monster_texture
var intent_card_resources: Array[CardResource]:
	get:
		return monster_resource.intent_card_resources
@onready var intent_icon: Sprite2D = $IntentIcon


func _ready() -> void:
	body_sprite = $Character/BodySprite


func _update_intent_icon(card: Card) -> void:
	## 设置意图图标，同时调整图标分辨率
	var tex: Texture2D = card.card_resource.texture if card else null
	if tex:
		intent_icon.texture = tex
		# 按固定高度缩放图标
		var tex_height = tex.get_height()
		if tex_height > 0:
			var target_height = float(Settings.ui_design_intent_icon_height)
			var scale_factor = target_height / tex_height
			intent_icon.scale = Vector2(scale_factor, scale_factor)
		else:
			intent_icon.scale = Vector2.ONE
	else:
		printerr("Missing intent texture for: " + intent_type)
		intent_icon.texture = null
		intent_icon.scale = Vector2.ONE


func init() -> void:
	## 进战初始化
	energy_slots = energy_slots_max.duplicate()
	health = health_max
	# 选择出生位置
	if is_ally:
		current_row = GlobalEnums.PositionRow.FRONT
	else:
		current_row = GlobalEnums.PositionRow.ENEMY
	# 设置角色纹理
	body_sprite.texture = monster_texture
	if body_sprite.texture and monster_resource.display_size != Vector2.ZERO:
		var tex_size = body_sprite.texture.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			body_sprite.scale = monster_resource.display_size / tex_size
	for intent in intent_card_resources:
		intent_cards.append(intent.create_card())
	if intent_cards.size() > 0:
		var first_card = get_intent()
		var info = _get_intent_description(first_card)
		_update_intent_icon(first_card)
		intent_type = info["type"]
		intent_value = info["value"]
		intent_changed.emit(intent_type, intent_value)

func start_turn() -> void:
	## 开始回合逻辑
	## 执行意图、根据回合数选择意图并广播
	# 调用父类开始回合逻辑
	super.start_turn()
	var intent_card = get_intent()
	if not intent_card:
		return
	var target = BattleManager.get_card_target()
	if intent_card and target:
		BattleManager.request_play_card(intent_card, self, target)
	exist_turn += 1
	return


func end_turn() -> void:
	## 结束回合
	var intent_card = get_intent()
	if not intent_card:
		return
	var info = _get_intent_description(intent_card)
	_update_intent_icon(intent_card)
	intent_type = info["type"]
	intent_value = info["value"]
	intent_changed.emit(intent_type, intent_value)
	# 调用父类结束回合逻辑
	super.end_turn()
	return


func get_intent() -> Card:
	## 获得意图卡牌，按照固定策略循环
	if intent_cards.is_empty():
		return null
	return intent_cards[exist_turn % intent_cards.size()]


func _get_intent_description(card: Card) -> Dictionary:
	## 获取意图卡牌的描述
	if card.effects.is_empty():
		return {"type": "unknown", "value": 0}
	 # 取第一个效果
	var effect = card.effects[0]
	var type = effect.effect_name if effect.effect_name != "" else "unknown"
	var value = effect.get_value()
	return {"type": type, "value": value}
