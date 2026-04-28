extends Control
class_name BattleUI

# 抓取界面上的节点
@onready var player_info: Label = $PlayerInfo
@onready var enemy_info: Label = $EnemyInfo
@onready var hand_container: HBoxContainer = $HandContainer
@onready var end_turn_btn: Button = $EndTurnBtn
@onready var replay_btn: Button = $ReplayBtn
@onready var game_info: Label = $GameInfo


var player: Player
var monster: Monster


func _ready() -> void:
	# 让 GameManager 先把角色注册进 BattleManager 再抓取
	await get_tree().process_frame
	
	# 获取玩家和怪物引用
	player = BattleManager.player
	for chara in BattleManager.turn_queue:
		if chara is Monster:
			monster = chara
			break
			
	if not player or not monster:
		print("UI报错：找不到玩家或怪物！")
		return
		
	# 底层的 health_changed 传了两个参数 (character, new_health)
	player.health_changed.connect(_on_player_health_changed)
	player.block_changed.connect(_on_player_block_changed)
	player.energy_changed.connect(_on_player_energy_changed)
	
	monster.health_changed.connect(_on_monster_health_changed)
	monster.intent_changed.connect(_on_monster_intent_changed)
	
	# 按钮点击事件
	end_turn_btn.pressed.connect(_on_end_turn_pressed)
	
	replay_btn.show() 
	replay_btn.pressed.connect(func(): BattleManager.reset_battle()) # 点击就重置场景
	
	# 初始刷新一次界面
	refresh_all_info()


# 信号接收处理函数 

func _on_player_health_changed(_character: Character, _new_health: int) -> void:
	refresh_all_info()


func _on_player_block_changed(_character: Character, _new_block: int) -> void:
	refresh_all_info()


func _on_player_energy_changed(_new_energy: int) -> void:
	refresh_all_info()


func _on_monster_health_changed(_character: Character, _new_health: int) -> void:
	refresh_all_info()


func _on_monster_intent_changed(type: String, value: int) -> void:
	# 怪物意图更新
	enemy_info.text = "【敌人】\n血量: %d/%d\n意图: %s (%d)" % [monster.health, monster.health_max, type, value]


# 界面刷新核心逻辑 
func refresh_all_info() -> void:
	# 更新玩家文本
	player_info.text = "【玩家】\n血量: %d/%d\n格挡: %d\n能量: %d/%d" % [
		player.health, player.health_max, player.block, player.energy, player.max_energy
	]
	
	# 更新怪物基础文本 (如果没有发意图信号的话)
	if monster.intent_type == "":
		enemy_info.text = "【敌人】\n血量: %d/%d\n意图: 未知" % [monster.health, monster.health_max]
	else:
		enemy_info.text = "【敌人】\n血量: %d/%d\n意图: %s (%d)" % [
			monster.health, monster.health_max, monster.intent_type, monster.intent_value]
	
	# 更新 gameinfo
	if player.health <= 0:
		game_info.text = "游戏结束：你倒下了！"
	elif monster.health <= 0:
		game_info.text = "游戏结束：胜利！"
	else:
		game_info.text = "第 %d 回合" % BattleManager.turn_count
		
	# 刷新手牌 (每次属性变化都重新画一遍手牌，防止手牌数量不对)
	_draw_hand_cards()


func _draw_hand_cards() -> void:
	# 先把旧的卡牌按钮全清空
	for child in hand_container.get_children():
		child.queue_free()
		
	# 根据玩家现在手里的牌，重新生成按钮
	for i in range(player.hand.size()):
		var card = player.hand[i]
		var btn = Button.new()
		# 按钮文字显示卡牌名和费用
		btn.text = "%s (%d费)" % [card.card_name, card.cost] 
		
		# 当按钮被按下时，执行打牌逻辑
		btn.pressed.connect(func():
			if player.is_energy_enough(card.cost) and BattleManager.active_character == player:
				player.play_card(card)
				refresh_all_info() # 打完牌刷新一下
		)
		hand_container.add_child(btn)


func _on_end_turn_pressed() -> void:
	# 按钮交互
	if BattleManager.active_character == player:
		player.end_turn()
		refresh_all_info()
