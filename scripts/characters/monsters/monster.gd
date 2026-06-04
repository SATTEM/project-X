class_name Monster
extends Character

signal intent_changed(type: String, value: int)
signal energy_changed()

var intent_cards: Array[ElementCard] = []
var intent_type: String = ""
var intent_value: int = 0
var exist_turn: int = 0
var energy_elements: Array[GlobalEnums.Element]:
	get:
		return monster_resource.energy_elements
var energy_slots_max: Dictionary[GlobalEnums.Element, int]
var energy_slots_boost: Dictionary[GlobalEnums.Element, int]
var energy_slots: Dictionary[GlobalEnums.Element, int]
var monster_resource: MonsterResource
var body_texture: Texture2D:
	get:
		return monster_resource.monster_texture
var intent_card_resources: Array[CardResource]:
	get:
		return monster_resource.intent_card_resources

var display_size: Vector2:
	get:
		return monster_resource.display_size



func _ready() -> void:
	world_ui = $CharacterWorldUI


func _update_intent_icon(card: ElementCard) -> void:
	## 设置意图图标
	if not world_ui:
		return
	var tex: Texture2D = card.card_resource.texture if card else null
	if tex:
		world_ui.intent_icon.texture = tex
		world_ui.intent_container.visible = true
		# 根据卡牌的不同属性，有不同表现
		_set_intent_icon_element(card)
	else:
		world_ui.intent_icon.texture = null
		world_ui.intent_container.visible = false


func _set_intent_icon_element(card: ElementCard) -> void:
	## 根据卡牌属性的不同，设置不同的表现方法
	## 这里采取添加对应颜色的遮罩作为实现
	world_ui.intent_icon.self_modulate = GlobalEnums.ElementColor[card.element]
	world_ui.intent_icon.self_modulate.a = Settings.ui_design_intent_shade_alpha


func init() -> void:
	## 基本初始化
	# 部分初始化能量槽
	for element in energy_elements:
		energy_slots_max[element] = 0
		energy_slots_boost[element] = 0
		energy_slots[element] = 0

	health = health_max
	# 初始化怪物牌组
	init_cards()
	# 完全初始化能量槽
	init_energy()


func battle_init() -> void:
	## 进战初始化
	# 选择出生位置
	if is_ally:
		current_row = GlobalEnums.PositionRow.FRONT
	else:
		current_row = GlobalEnums.PositionRow.ENEMY
	# UI组件初始化
	world_ui.setup(self)
	# 进战自带满能量
	energy_slots = energy_slots_max.duplicate()
	energy_changed.emit()
	# 初始化第一轮意图
	if intent_cards.size() > 0:
		var first_card = get_intent()
		var info = _get_intent_description(first_card)
		_update_intent_icon(first_card)
		intent_type = info["type"]
		intent_value = info["value"]
		intent_changed.emit(intent_type, intent_value)	


func init_cards() -> void:
	## 初始化怪物卡组
	for intent in intent_card_resources:
		# 根据基础卡牌生成指定范围内随机属性的元素卡牌
		var normal_card: Card = intent.create_card()
		var element = energy_elements[randi() % energy_elements.size()]
		var element_card = ElementCard.build_from_card(normal_card, element)
		intent_cards.append(element_card)


func init_energy() -> void:
	monster_resource.energy_strategy.energy_startegy_assign(self)


func start_turn() -> void:
	## 开始回合逻辑
	## 执行意图、根据回合数选择意图并广播
	# 调用父类开始回合逻辑
	super.start_turn()
	boost_energy()
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


func boost_energy() -> void:
	## 回合开始时回复能量
	for element in energy_elements:
		energy_slots[element] = min(
				energy_slots[element] + energy_slots_boost[element],
				energy_slots_max[element]
		)
	energy_changed.emit()


func is_energy_enough(card: Card) -> bool:
	if not card is ElementCard:
		printerr("Monster's card should have element")
		return false
	card = card as ElementCard
	return energy_slots[card.element] >= card.cost


func spend_energy(card: Card) -> void:
	## 扣除对应槽的能量
	if not card is ElementCard:
		printerr("Monster's card should have element")
		return
	card = card as ElementCard
	energy_slots[card.element] -= card.cost
	energy_changed.emit()
	return


func get_intent() -> ElementCard:
	## 获得意图卡牌，按照固定策略循环
	if intent_cards.is_empty():
		return null
	return intent_cards[exist_turn % intent_cards.size()]


func _get_intent_description(card: ElementCard) -> Dictionary:
	## 获取意图卡牌的描述
	if card.effects.is_empty():
		return {"type": "unknown", "value": 0}
	 # 取第一个效果
	var effect = card.effects[0]
	var type = effect.effect_name if effect.effect_name != "" else "unknown"
	var value = effect.get_value()
	return {"type": type, "value": value}
