extends Control
class_name BattleUI

var player: Player
var monster: Monster

# 抓取界面上的节点
@onready var player_info: Label = $PlayerInfo
@onready var enemy_info: Label = $EnemyInfo
@onready var hand_container: HBoxContainer = $HandContainer
@onready var end_turn_btn: Button = $EndTurnBtn
@onready var replay_btn: Button = $ReplayBtn
@onready var game_info: Label = $GameInfo


func _ready() -> void:
	# 让 GameManager 先把角色注册进 BattleManager 再抓取
	await get_tree().process_frame
	
	# 获取玩家引用
	player = BattleManager.player
	if not player:
		print("UI报错：找不到玩家！")
		return
		
	# 玩家相关信号
	player.health_changed.connect(_on_player_health_changed)
	player.block_changed.connect(_on_player_block_changed)
	player.energy_changed.connect(_on_player_energy_changed)

	# 按钮点击事件
	end_turn_btn.pressed.connect(_on_end_turn_pressed)
	replay_btn.show() 
	# 点击就重置场景
	replay_btn.pressed.connect(func(): BattleManager.reset_battle())
	# 游戏未结束时不显示
	replay_btn.hide()
	# 连接主动刷新信号
	BattleManager.call_refresh.connect(refresh_all_info)
	# 初始刷新一次界面
	refresh_all_info()


# 信号接收处理函数 

func _on_player_health_changed(_character: Character, _new_health: int) -> void:
	refresh_all_info()


func _on_player_block_changed(_character: Character, _new_block: int) -> void:
	refresh_all_info()


func _on_player_energy_changed(_new_energy: int) -> void:
	refresh_all_info()


func refresh_all_info() -> void:
	## 界面刷新逻辑
	# 更新玩家文本
	player_info.text = "【玩家】\n血量: %d/%d\n格挡: %d\n能量: %d/%d" % [
		player.health, player.health_max, player.block, player.energy, player.max_energy
	]

	# 更新敌人信息
	var enemy = _get_first_enemy()
	if enemy:
		enemy_info.text = "【敌人】\n血量: %d/%d\n意图: %s (%d)" % [
			enemy.health, enemy.health_max, enemy.intent_type, enemy.intent_value
		]
	else:
		enemy_info.text = "【敌人】\n无"

	# 更新游戏状态
	if player.health <= 0:
		game_info.text = "游戏结束：你倒下了！"
		replay_btn.show()
		end_turn_btn.disabled = true
	elif enemy == null:
		game_info.text = "游戏结束：胜利！"
		replay_btn.show()
		end_turn_btn.disabled = true
	else:
		game_info.text = "第 %d 回合" % BattleManager.turn_count
		replay_btn.hide()
		end_turn_btn.disabled = false

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
		# 添加样式
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_hover_color", Color.YELLOW)
		btn.add_theme_stylebox_override("normal", _make_card_stylebox(Color(0.2, 0.2, 0.3)))
		btn.add_theme_stylebox_override("hover", _make_card_stylebox(Color(0.3, 0.3, 0.4)))
		btn.custom_minimum_size = Vector2(100, 60)
		# 当按钮被按下时，执行打牌逻辑
		btn.pressed.connect(func():
			if (
					player.is_energy_enough(card.cost)
					and BattleManager.active_character == player
					and player.hand.has(card)
			):
				var target = BattleManager.get_card_target()
				if target:
					BattleManager.request_play_card(card, player, target)
					refresh_all_info()
)	
		hand_container.add_child(btn)


func _make_card_stylebox(bg_color: Color) -> StyleBoxFlat:
	## 创建卡牌样式
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.WHITE
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	return style


func _on_end_turn_pressed() -> void:
	## 按钮交互
	if BattleManager.active_character == player:
		player.end_turn()
		refresh_all_info()


func _process(_delta: float) -> void:
	if BattleManager.can_next_turn:
		refresh_all_info()


func _get_first_enemy() -> Monster:
	## 辅助函数：获取第一个存活敌人
	for child in BattleManager.position_rows[GlobalEnums.PositionRow.ENEMY].get_children():
		if child is Monster and not child.is_dead:
			return child
	return null
