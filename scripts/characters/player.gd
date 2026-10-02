class_name Player
extends Character

signal energy_changed(new_energy: int)
signal piles_changed(draw_count: int, discard_count: int)
signal cards_drawn(cards: Array[Card])
signal card_discarded(card: Card)
signal hand_limit_exceeded(discarded_count: int)

@export var texture: Texture2D
@export_range(1, 20, 1) var max_hand_size: int = 7
var energy: int # 当前能量
var max_energy: int = 5 # 最大能量
var hand: Array[Card] = [] # 手牌
var draw_pile: Array = [] # 抽牌堆
var discard_pile: Array = []  # 弃牌堆
var display_size: Vector2:
	get:
		return Settings.ui_design_player_display_size
var body_texture: Texture2D:
	get:
		return texture


func _ready() -> void:
	world_ui = $CharacterWorldUI


static func get_default_deck_ids() -> Array[String]:
	## 硬编码默认牌组id
	return [
		"attack_card",
		"attack_card",
		"defend_card",
		"defend_card",
		"draw_card",
		"draw_card",
		"summon_card",
		"summon_card",
	]


func init() -> void:
	## 创建角色时初始化
	is_ally = true


func battle_init(player_state: PlayerState = null) -> void:
	## 进战初始化
	# 临时处理: 进战时才进行角色初始化
	init()
	is_dead = false
	block = 0
	_clear_hand_and_decks()
	if player_state:
		apply_player_state(player_state)
	else:
		init_deck()
		health = health_max
	world_ui.setup(self)
	current_row = GlobalEnums.PositionRow.PLAYER


func start_turn() -> void:
	## 开始回合
	# 父类开始逻辑
	super.start_turn()
	# 初始化能量, 抽5张牌
	energy = max_energy
	draw_card(5)
	energy_changed.emit(energy)
	return


func end_turn() -> void:
	## 结束回合
	# 必须是玩家回合才能结束
	if BattleManager.active_character != self:
		printerr("Can't end other's turn!")
		return

	for card in hand:
		discard(card) # 手牌全部扔进弃牌堆
	hand.clear()    # 清空手牌
	
	print("玩家回合结束...")
	# 父类结束回合逻辑
	super.end_turn()
	return


func init_deck() -> void:
	## 初始化抽牌堆
	print("玩家卡组初始化中...")
	build_deck_from_ids(get_default_deck_ids())


func apply_player_state(player_state: PlayerState) -> void:
	if not player_state:
		return
	health_max = player_state.max_hp
	is_dead = false
	health = clamp(player_state.current_hp, 0, health_max)
	build_deck_from_ids(player_state.deck_ids, player_state.summon_bindings)


func build_deck_from_ids(deck_ids: Array[String], summon_bindings: Array[String] = []) -> void:
	## 从ID列表构造卡组
	_clear_hand_and_decks()
	for index in range(deck_ids.size()):
		var card_id := deck_ids[index]
		var card = CardLibrary.create_card_and_add_to_scene(card_id, BattleManager.card_container)
		if card:
			if index < summon_bindings.size() and not summon_bindings[index].is_empty():
				card.set_summon_binding(summon_bindings[index])
			draw_pile.append(card)
	draw_pile.shuffle()
	_emit_piles_changed()


func draw_card(amount: int) -> void:
	## 从抽牌堆取牌加入手牌，若抽牌堆不足则洗入弃牌堆
	var drawn_cards: Array[Card] = []
	var overflow_count := 0
	for i in range(amount):
		if draw_pile.is_empty():
			_reshuffle_discard_to_draw()

		if not draw_pile.is_empty():
			var card: Card = draw_pile.pop_front() # 拿走第一张
			if hand.size() < max_hand_size:
				hand.append(card)
				drawn_cards.append(card)
			else:
				# 手牌已满时，仍视为完成抽牌，但卡牌直接进入弃牌堆。
				discard_pile.append(card)
				card_discarded.emit(card)
				overflow_count += 1
	_emit_piles_changed()
	if not drawn_cards.is_empty():
		cards_drawn.emit(drawn_cards)
	if overflow_count > 0:
		hand_limit_exceeded.emit(overflow_count)


func discard(card: Card) -> void:
	## 弃牌方法
	discard_pile.append(card)
	_emit_piles_changed()
	card_discarded.emit(card)


func is_energy_enough(card: Card) -> bool:
	## 检查费用：检查角色是否有足够能量
	return energy >= card.cost


func spend_energy(card: Card) -> void:
	## 扣除能量
	energy -= card.cost
	if energy < 0:   
		energy = 0  
	energy_changed.emit(energy)
	return


func gain_energy(amount: int) -> int:
	## 回复能量并返回实际回复值，供献祭、过载等效果复用。
	if amount <= 0:
		return 0
	var previous_energy := energy
	energy = clampi(energy + amount, 0, max_energy)
	var gained_energy := energy - previous_energy
	if gained_energy > 0:
		energy_changed.emit(energy)
	return gained_energy


func _input(event):
	## 处理输入
	# 忽略无效状态
	if not BattleManager.is_active or BattleManager.active_character != self:
		return
	if event.is_action_pressed("ui_accept"): #按回车键下一个回合
		end_turn()


func _reshuffle_discard_to_draw() -> void:
	#洗牌 : 将弃牌堆的牌复制到抽牌堆,随机打乱抽牌堆,清空弃牌堆
	print("抽牌堆空了，正在洗弃牌堆...")
	draw_pile = discard_pile.duplicate()
	draw_pile.shuffle() # 随机打乱
	discard_pile.clear()
	_emit_piles_changed()


func _clear_hand_and_decks() -> void:
	## 清理手牌和抽牌堆
	if hand == null:
		hand = []
	else:
		_queue_free_cards(hand)
		hand.clear()
	_queue_free_cards(draw_pile)
	_queue_free_cards(discard_pile)
	draw_pile.clear()
	discard_pile.clear()
	_emit_piles_changed()


func _emit_piles_changed() -> void:
	piles_changed.emit(draw_pile.size(), discard_pile.size())


func _queue_free_cards(cards: Array) -> void:
	## 释放所有卡牌节点
	for card in cards:
		if card and is_instance_valid(card):
			card.queue_free()
