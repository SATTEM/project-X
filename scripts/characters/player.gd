class_name Player
extends Character

var draw_pile: Array = [] #抽牌堆
var discard_pile: Array = []  #弃牌堆

func init_deck() -> void:
	print("玩家卡组初始化中...")

func draw_card(amount: int) -> void:
	#从抽牌堆取牌加入手牌，若抽牌堆不足则洗入弃牌堆
	for i in range(amount):
		if draw_pile.is_empty():
			_reshuffle_discard_to_draw()

		if not draw_pile.is_empty():
			var card = draw_pile.pop_back() # 拿走最后一张
			hand.append(card)

func _reshuffle_discard_to_draw() -> void:
	#洗牌 : 将弃牌堆的牌复制到抽牌堆,随机打乱抽牌堆,清空弃牌堆
	print("抽牌堆空了，正在洗弃牌堆...")
	draw_pile = discard_pile.duplicate()
	draw_pile.shuffle() # 随机打乱
	discard_pile.clear()

func start_turn() -> void:
	#回合开始 : 初始化能量, 抽5张牌
	energy = max_energy
	draw_card(5) 

func end_turn() -> void:
	#结束回合
	turn_ended.emit(self)
	
	for card in hand:
		discard_pile.append(card) #手牌全部扔进弃牌堆
	hand.clear()    #清空手牌
	
	block = 0 #格挡值归0
	print("玩家回合结束...")


#下面是测试函数,很无聊的测试函数
func _input(event):
	if event.is_action_pressed("ui_accept"): #按回车键模拟受击
		print("按下回车，模拟受到 10 点伤害")
		take_damage(10)
		print("剩余血量：", health, " 剩余格挡：", block)
	
	if event.is_action_pressed("ui_focus_next"): #按Tab键模拟加防御
		print("按下 Tab，增加 5 点格挡")
		add_block(5)
