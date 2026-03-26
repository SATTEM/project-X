extends Node
## 战斗场景


# 在编辑器中设置默认卡牌，这里直接用实例，后续要用CardResource生成Card实例
@export var default_card: Card
# 手动添加角色
@export var player: Character
@export var characters: Array[Character]


func _ready() -> void:
	## 场景准备完成，连接信号
	# 打出卡牌信号
	default_card.played.connect(_on_card_played)
	# 抽牌请求
	player.draw_required.connect(_on_player_draw_required)
	# 角色死亡
	player.character_died.connect(_on_character_died)
	# 玩家结束回合
	player.turn_ended.connect(_on_character_turn_ended)
	# 其他角色结束回合
	for ch in characters:
		ch.turn_ended.connect(_on_character_turn_ended)
	
	# 配置好信号之后，调用玩家回合开始函数，开始游戏
	player.start_turn()
	
	return


func _process(delta: float) -> void:
	## 帧循环
	pass

func _on_player_draw_required(count: int) -> void:
	## 给玩家抽若干张牌
	# 正式实现方法: 角色调用自己的抽牌函数
	#character.draw_cards(count)
	# 这里简单实现，直接添加一张默认牌
	print("Drawing card")
	player.hand.append(default_card)
	return


func _on_card_played(card: Card = default_card) -> void:
	## 结算卡牌实例，这里使用默认卡牌
	print("Playing card!")
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


func start_turn(character: Character) -> void:
	## 开始某个角色的回合
	if character == player:
		print("It's player's turn!")
	else:
		print("It's someone else's turn!")
	
	character.start_turn()
	return


func get_card_target() -> Character:
	return characters[0]


func _on_character_turn_ended(character: Character) -> void:
	## 角色回合结束，决定下一个是谁的回合
	player.start_turn()
	return
	


func end_game() -> void:
	## 结束游戏
	print("Game end...")
	get_tree().quit()
	return
