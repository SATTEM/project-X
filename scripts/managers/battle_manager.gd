extends Node
## 战斗管理器脚本

# 通过注册来获取卡牌和角色的引用
var player: Player
var turn_queue: Array[Character]
var active_character: Character = null
var current_character_index: int = 0
var battle_over: bool = false
var turn_count: int = 1
var can_next_turn: bool = false
var is_active: bool = false


func _on_card_played(card: Card) -> void:
	## 结算卡牌实例
	# 获取卡牌目标
	var target: Character = get_card_target()
	# 对目标使用卡牌
	card.play_card_on_target(active_character, target)
	return


func _on_character_died(character: Character) -> void:
	## 当有角色死亡时调用此方法
	## 目前来说是检查是否为玩家，是则失败，否则胜利
	if battle_over:
		return
	if character == player:
		print("You died!")
	else:
		print("You win!")
	battle_over = true
	end_game()
	return


func _on_character_turn_ended(_character: Character) -> void:
	## 角色回合结束，标记可以进入下一个回合
	if battle_over:
		return
	can_next_turn = true	
	return


func _process(_delta: float) -> void:
	## 每一帧检查按帧变化的逻辑标志
	if can_next_turn:
		print(active_character.name + "的回合结束")
		current_character_index = (current_character_index + 1) % turn_queue.size()
		if current_character_index == 0:
			turn_count += 1
		can_next_turn = false
		start_character_turn(turn_queue[current_character_index])


func register_card(card: Card) -> void:
	card.played.connect(_on_card_played)
	print("Registered: " + card.card_name)
	return


func register_character(character: Character) -> void:
	## 注册角色，并连接共有信号
	turn_queue.append(character)
	if character is Player:
		player = character
		player.init_deck()
	# 角色死亡
	character.character_died.connect(_on_character_died)
	# 角色结束回合
	character.turn_ended.connect(_on_character_turn_ended)
	print("Registered: " + character.name)
	return


func start_battle(aPlayer: Player, enemies: Array[Monster]):
	## 战斗初始化方法
	## 注册战斗开始时就存在的玩家、敌人
	## 并完成对应初始化
	
	turn_queue.clear()      # 清空上局的死人队列
	battle_over = false     # 重置战斗结束标志
	turn_count = 1          # 回合数归零重计
	can_next_turn = false   # 锁住回合流转逻辑
	
	is_active = true
	# 处理玩家
	player = aPlayer
	player.battle_init()
	register_character(player)
	# 处理敌人
	for enemy in enemies:
		register_character(enemy)
	current_character_index = 0
	start_character_turn(turn_queue[current_character_index])
	return


func start_character_turn(character: Character) -> void:
	## 开始某个角色的回合，若为玩家则等待输入
	active_character = character
	
	character.start_turn()
	if character is Player:
		# 玩家的操作逻辑在Player内执行
		pass
	else:
		character.execute_intent()
		character.end_turn()


func reset_battle() -> void:
	## 重置战斗
	get_tree().reload_current_scene()
	is_active = true
	return


func get_card_target() -> Character:
	## 选择卡牌打击对象
	## 敌人打击玩家，玩家和随从打击敌人
	if active_character is Player:
		for chara in turn_queue:
			if chara is Monster : 
				return chara
		return player
	else:
		if active_character.is_ally:
			# 随从
			return player
		else:
			# 敌人
			return player


func end_game() -> void:
	## 结束游戏
	is_active = false
	print("Game end...")
	get_tree().quit()
	return
