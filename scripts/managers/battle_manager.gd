class_name BattleMananger
extends Node
## 战斗管理器脚本

# 通过注册来获取卡牌和角色的引用
var player: Character
var default_card: Card
var characters: Array[Character]
var test_timer: float = 0.0
var turn_count: int = 0


func _process(delta: float) -> void:
	## 帧循环
	# 测试: 当每隔一秒开始一回合
	test_timer += delta
	if test_timer >= 1.0 :
		turn_count += 1
		print("Turn: " + str(turn_count))
		test_timer = 0.0
		start_turn(player)
	return


func _on_player_draw_required(count: int) -> void:
	## 给玩家抽若干张牌
	# 正式实现方法: 角色调用自己的抽牌函数
	#character.draw_cards(count)
	# 这里简单实现，直接添加默认牌
	for i in range(count):
		player.hand.append(default_card)
		print(str(i + 1) + " card drawed: " + default_card.card_name)
	return


func _on_card_played(card: Card = default_card) -> void:
	## 结算卡牌实例，这里使用默认卡牌
	# 获取卡牌目标
	var target: Character = get_card_target()
	# 对目标使用卡牌
	card.play_card_on_target(target)
	return


func _on_character_died(character: Character) -> void:
	## 当有角色死亡时调用此方法
	## 目前来说是检查是否为玩家，是则失败，否则胜利
	if character == player:
		print("You died!")
	else:
		print("You win!")
		
	end_game()
	return


func _on_character_turn_ended(character: Character) -> void:
	## 角色回合结束，决定下一个是谁的回合
	print("Turn ended, character's health: " + str(character.health))
	return


func register_card(card: Card) -> void:
	default_card = card 
	card.played.connect(_on_card_played)
	print("Registered: " + card.card_name)
	return


func register_player(character: Character) -> void:
	player = character
	# 抽牌请求
	player.draw_required.connect(_on_player_draw_required)
	# 角色死亡
	player.character_died.connect(_on_character_died)
	# 玩家结束回合
	player.turn_ended.connect(_on_character_turn_ended)
	print("Registered: " + character.name)
	return


func start_turn(character: Character) -> void:
	## 开始某个角色的回合
	if character == player:
		print("It's player's turn!")
	else:
		print("It's someone else's turn!")
	
	character.start_turn()
	return


func get_card_target() -> Character:
	return player


func end_game() -> void:
	## 结束游戏
	print("Game end...")
	get_tree().quit()
	return
