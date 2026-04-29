class_name Player
extends Character

signal energy_changed(new_energy: int)

var energy: int # 当前能量
var max_energy: int = 5# 最大能量
var draw_pile: Array = [] # 抽牌堆
var discard_pile: Array = []  # 弃牌堆


func init() -> void:
	## 创建角色时初始化
	# 初始化卡组
	init_deck()


func battle_init() -> void:
	## 进战初始化
	# 临时处理: 进战时才进行角色初始化
	init()


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
	assert(BattleManager.active_character == self, "Can't end other's turn!")

	for card in hand:
		discard_pile.append(card) #手牌全部扔进弃牌堆
	hand.clear()    #清空手牌
	
	block = 0 #格挡值归0
	print("玩家回合结束...")
	# 父类结束回合逻辑
	super.end_turn()
	return


func init_deck() -> void:
	## 初始化抽牌堆：放入5张攻击牌、3张防御牌、2张抽牌牌
	print("玩家卡组初始化中...")
	var attack_res = preload("res://scripts/cards/resources/attack_card.tres")
	var defend_res = preload("res://scripts/cards/resources/defend_card.tres")
	var draw_res = preload("res://scripts/cards/resources/draw_card.tres")
	for i in range(5):
		var card = Card.new()
		card.card_resource = attack_res
		add_child(card)
		draw_pile.append(card)
	for i in range(3):
		var card = Card.new()
		card.card_resource = defend_res
		add_child(card)
		draw_pile.append(card)
	for i in range(2):
		var card = Card.new()
		card.card_resource = draw_res
		add_child(card)
		draw_pile.append(card)
	draw_pile.shuffle()


func draw_card(amount: int) -> void:
	## 从抽牌堆取牌加入手牌，若抽牌堆不足则洗入弃牌堆
	## effect
	for i in range(amount):
		if draw_pile.is_empty():
			_reshuffle_discard_to_draw()

		if not draw_pile.is_empty():
			var card = draw_pile.pop_back() # 拿走最后一张
			hand.append(card)


func is_energy_enough(need: int) -> bool:
	## 检查费用：检查角色是否有足够能量
	return energy >= need


func spend_energy(need: int) -> void:
	# 扣除费用：扣除能量
	energy -= need
	if energy < 0:   
		energy = 0  
	energy_changed.emit(energy)
	return


func play_card(card: Card) -> void:
	## 打出手牌：检查是否能打出，若能则扣费打出、调用其打牌方法
	if is_energy_enough(card.cost):
		spend_energy(card.cost)
		card.play()
		# 能打出此牌，则打出后弃掉
		discard_pile.append(card)
		hand.erase(card)
	else:
		print("能量不足,无法打出卡牌")
	return


func _input(event):
	## 处理输入
	# 忽略无效状态下的入
	if not BattleManager.is_active or BattleManager.active_character != self:
		return
	if event.is_action_pressed("ui_accept"): #按回车键下一个回合
		# 打出第一张牌
		play_card(hand[0])
		end_turn()
	
	if event.is_action_pressed("ui_focus_next"): #按Tab键模拟加防御
		print("按下 Tab，增加 5 点格挡")
		add_block(5)


func _reshuffle_discard_to_draw() -> void:
	#洗牌 : 将弃牌堆的牌复制到抽牌堆,随机打乱抽牌堆,清空弃牌堆
	print("抽牌堆空了，正在洗弃牌堆...")
	draw_pile = discard_pile.duplicate()
	draw_pile.shuffle() # 随机打乱
	discard_pile.clear()
