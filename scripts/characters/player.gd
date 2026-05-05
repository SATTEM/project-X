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
	is_ally = true


func battle_init() -> void:
	## 进战初始化
	# 临时处理: 进战时才进行角色初始化
	init()
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
		discard_pile.append(card) # 手牌全部扔进弃牌堆
	hand.clear()    # 清空手牌
	
	print("玩家回合结束...")
	# 父类结束回合逻辑
	super.end_turn()
	return


func init_deck() -> void:
	## 初始化抽牌堆
	print("玩家卡组初始化中...")
	draw_pile.clear()
	for i in range(2):
		var card = CardLibrary.create_card_and_add_to_scene("attack_card", BattleManager.card_container)
		draw_pile.append(card)
	for i in range(2):
		var card = CardLibrary.create_card_and_add_to_scene("defend_card", BattleManager.card_container)
		draw_pile.append(card)
	for i in range(2):
		var card = CardLibrary.create_card_and_add_to_scene("draw_card", BattleManager.card_container)
		draw_pile.append(card)
	for i in range(2):
		var card = CardLibrary.create_card_and_add_to_scene("summon_card", BattleManager.card_container)
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
	drawing.emit(amount)


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
