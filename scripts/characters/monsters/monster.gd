class_name Monster
extends Character

signal intent_changed(type: String, value: int)
signal energy_changed()

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
var play_loop_count: int:
	get:
		return monster_resource.play_loop_count

var display_size: Vector2:
	get:
		return monster_resource.display_size
var play_strategy: MonsterPlayStrategy:
	get:
		var strategy = monster_resource.play_strategy
		if not strategy:
			# 默认使用自私策略
			strategy = SelfishStrategy.new()
		return strategy
var disabled_elements: Array[GlobalEnums.Element] = [] # 记录当前被禁用的元素
var energy_threshold: int = 5  # 能量爆气阈值，达到此数值触发清空与增幅
var card_pool: Dictionary[int, Array] = {} # 运行时牌池，Array[ElementCard]
var hand: Array[ElementCard] = []
var display_node: Node2D 

@export var summon_cost: int = 2  # 随从基础召唤费用,默认为2
@export var intent_icon: Texture2D



func _ready() -> void:
	world_ui = $CharacterWorldUI


func _update_intent_icon(card: ElementCard) -> void:
	if not world_ui:
		return
	
	var tex: Texture2D = null
	var info = _get_intent_description(card)
	print("意图类型:", info["type"])
	match info["type"]:
		"damage":
			tex = preload("res://assets/art/intents/damage.png")
		"block":
			tex = preload("res://assets/art/intents/block.png")
		_:
			tex = preload("res://assets/art/intents/default.png")
	
	if tex:
		world_ui.intent_icon.texture = tex
		world_ui.intent_container.visible = true
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
	# 确保能量槽已初始化
	if energy_slots_max.is_empty():
		init_energy()
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
	if not card_pool.is_empty():
		var first_card = get_intent()
		if first_card:
			var info = _get_intent_description(first_card)
			_update_intent_icon(first_card)
			intent_type = info["type"]
			intent_value = info["value"]
			intent_changed.emit(intent_type, intent_value)
	var body_sprite = world_ui.get_node("body_sprite")
	if body_sprite:
		# 如果有动画，创建动画节点
		if monster_resource and monster_resource.monster_animation_frames:
			var anim_body = AnimatedSprite2D.new()
			anim_body.name = "anim_body"
			anim_body.sprite_frames = monster_resource.monster_animation_frames
			var first_frame = anim_body.sprite_frames.get_frame_texture("idle", 0)
			if first_frame:
				var tex_size = first_frame.get_size()
				var target_size = Vector2(170, 170)
				anim_body.scale = target_size / tex_size
			anim_body.position = body_sprite.position + Vector2(0, -30)
			anim_body.play("idle")
			body_sprite.visible = false
			world_ui.add_child(anim_body)
			display_node = anim_body
		else:
			# 没有动画，保持静态图
			body_sprite.visible = true


func init_cards() -> void:
	## 初始化怪物牌池：从 intent_card_map 构建 card_pool
	card_pool.clear()
	var card_map = monster_resource.intent_card_map
	for appear_turn in card_map:
		var card_resources: Array = card_map[appear_turn]
		if card_resources.is_empty():
			continue
		var cards: Array[ElementCard] = []
		for card_resource in card_resources:
			if not card_resource:
				continue
			var normal_card: Card = card_resource.create_card()
			var element = energy_elements[randi() % energy_elements.size()]
			var element_card = ElementCard.build_from_card(normal_card, element, appear_turn)
			cards.append(element_card)
		card_pool[appear_turn] = cards


func init_energy() -> void:
	monster_resource.energy_strategy.energy_startegy_assign(self)


func start_turn() -> void:
	## 开始回合逻辑
	## 1. 把当前回合的牌抽到手上 2. 按策略逐张尝试打出
	super.start_turn()
	boost_energy()
	
	_try_play_hand(play_strategy)
	
	exist_turn += 1
	return


func _draw_hand() -> void:
	## 抽牌：从 card_pool 取出当前 appear_turn 对应的所有卡牌
	var turn_in_loop = exist_turn % play_loop_count
	hand = []
	if card_pool.has(turn_in_loop):
		hand = card_pool[turn_in_loop].duplicate()


func _try_play_hand(strategy: MonsterPlayStrategy) -> bool:
	## 按策略从手牌中选牌尝试打出，直到成功或遍历完
	_draw_hand()
	if hand.is_empty():
		return false
	var remaining = hand.duplicate()
	var all_chars = BattleManager.get_all_character()
	while not remaining.is_empty():
		var card = strategy.select_card(remaining, self)
		if not card:
			break
		remaining.erase(card)
		if not is_energy_enough(card):
			continue
		var target = strategy.choose_target(card, self, all_chars)
		if target:
			BattleManager.request_play_card(card, self, target)
			return true
	return false


func end_turn() -> void:
	## 结束回合
	var intent_card = get_intent()
	if intent_card:
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
		# 如果该元素被禁用了，就跳过它的能量回复
		if disabled_elements.has(element):
			continue
			
		energy_slots[element] = min(
				energy_slots[element] + energy_slots_boost[element],
				energy_slots_max[element]
		)
		# 每次自然回蓝后检查阈值
		_check_energy_threshold(element)
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
	## 获得意图卡牌，从 card_pool 按 appear_turn 查找
	if card_pool.is_empty():
		return null
	var turn_in_loop = exist_turn % play_loop_count
	if card_pool.has(turn_in_loop):
		var cards: Array = card_pool[turn_in_loop]
		if not cards.is_empty():
			return cards[0]
	return null


func _get_intent_description(card: ElementCard) -> Dictionary:
	## 获取意图卡牌的描述
	if card.effects.is_empty():
		return {"type": "unknown", "value": 0}
	 # 取第一个效果
	var effect = card.effects[0]
	var type = effect.effect_name if effect.effect_name != "" else "unknown"
	var value = effect.get_value()
	return {"type": type, "value": value}


func upgrade_attribute(stat_name: String, bonus_value: int) -> void:
	## 供商店/事件调用：花钱提升随从的属性（例如最大生命值）
	if stat_name == "max_hp":
		health_max += bonus_value
		# 提升上限的同时，把当前的血量也加上去
		health += bonus_value 
		print("随从 ", self.name, " 升级了最大生命值！当前最大生命: ", health_max)
	else:
		print(" 未知的随从属性修改请求: ", stat_name)


func modify_energy_recovery_manually(slot: GlobalEnums.Element, bonus_amount: int) -> void:
	## 供商店/事件调用：花钱永久提升随从某个元素每回合的能量恢复数值
	# 检查怪物当前持有的策略是不是平均恢复策略
	if monster_resource and monster_resource.energy_strategy is AverageEnergyStrategy:
		var strategy = monster_resource.energy_strategy as AverageEnergyStrategy
		strategy.recovery_amount += bonus_amount
		print(" 随从 ", self.name, " 的元素 [", slot, "] 回复效率提升了！当前每回合回复: ", strategy.recovery_amount)
	else:
		print(" 当前随从的能量恢复策略不支持直接修改数值")


# === 元素卡牌交互机制 ===

func modify_element_points(element: GlobalEnums.Element, amount: int) -> void:
	## 供外部卡牌调用：增加或减少特定元素点
	if not energy_slots.has(element):
		return
	
	# 修改能量点，并确保不低于0，不高于上限
	energy_slots[element] = clamp(energy_slots[element] + amount, 0, energy_slots_max[element])
	# 如果是增加能量（充能），检查是否触发阈值
	if amount > 0:
		_check_energy_threshold(element)

	energy_changed.emit()
	print(self.name, " 的 [", element, "] 元素点变化了 ", amount, "，当前为: ", energy_slots[element])


func disable_element(element: GlobalEnums.Element) -> void:
	## 供外部卡牌调用：直接禁用某个元素
	if not disabled_elements.has(element):
		disabled_elements.append(element)
		# 禁用时，顺便清空该属性现有的能量
		if energy_slots.has(element):
			energy_slots[element] = 0
			energy_changed.emit()
		print(self.name, " 的 [", element, "] 属性被卡牌禁用了！")


func _check_energy_threshold(element: GlobalEnums.Element) -> void:
	## 检查单项能量是否达到阈值
	if energy_slots[element] >= energy_threshold:
		print(self.name, " 的 [", element, "] 能量达到满值！触发爆气！")
		# 清空该属性的能量
		energy_slots[element] = 0
		# 给予该怪物增幅
		_apply_element_buff(element)


func _apply_element_buff(element: GlobalEnums.Element) -> void:
	## 给予怪物增幅的具体逻辑：完美对接 BuffPool，三系专属机制！
	print(" 怪物能量爆满！触发 [", element, "] 系专属增幅！")
	
	var burst_buff: BuffResource = null
	
	# 根据设定的三大元素，动态生成对应的 Buff
	match element:
		GlobalEnums.Element.FIRE:
			# 火系爆气：获得力量增幅
			var fire_buff = PowerBuff.new()
			fire_buff.buff_name = "烈火·狂暴"
			fire_buff.bonus_damage = 5  # 伤害 +5
			fire_buff.duration = 3  # 设定为 3 回合
			burst_buff = fire_buff
			
		GlobalEnums.Element.SOIL:
			# 土系爆气：获得吸血附魔
			var soil_buff = LifestealBuff.new()
			soil_buff.buff_name = "厚土·汲取"
			soil_buff.heal_value = 3    # 吸血 +3
			soil_buff.duration = 3  # 设定为 3 回合
			burst_buff = soil_buff
			
		GlobalEnums.Element.WATER:
			# 水系爆气：获得减费增幅
			var water_buff = CostReductionBuff.new()
			water_buff.buff_name = "流水·轻灵"
			water_buff.cost_reduction = 1 # 下一张牌耗能 -1
			water_buff.duration = 1  # 设定为 1 回合
			burst_buff = water_buff
			
		_:
			# UNKNOWN 或异常情况：兜底加护盾
			if self.has_method("add_block"):
				self.add_block(10)
				print("获得无属性共鸣：10点格挡")
				
	# 如果成功生成了 Buff，就塞进流水线里
	if burst_buff != null:
		if "buff_pool" in self:
			self.buff_pool.append(burst_buff)
			print("成功挂载 Buff：", burst_buff.buff_name, "，当前 Buff 池数量：", self.buff_pool.size())
		else:
			printerr("错误：角色身上没有 buff_pool 数组！")
