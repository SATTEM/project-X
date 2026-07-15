extends Control
class_name BattleUI

var player: Player
var monster: Monster

@export var card_display_scene: PackedScene
@export var deck_preview_overlay_scene: PackedScene
@export var settings_overlay_scene: PackedScene

# 抓取界面上的节点
@onready var player_info: Label = $PlayerInfo
@onready var enemy_info: Label = $EnemyInfo
@onready var hand_container: HBoxContainer = $HandContainer
@onready var end_turn_btn: Button = $EndTurnBtn
@onready var replay_btn: Button = $ReplayBtn
@onready var game_info: Label = $GameInfo
@onready var back_menu_btn: Button = $BackMenuBtn
@onready var settings_btn: Button = $SettingsBtn
@onready var energy_label: Label = $Energy
@onready var draw_pile_button: CardPileButton = $DrawPileButton
@onready var discard_pile_button: CardPileButton = $DiscardPileButton
var _selecting_target: bool = false
var _pending_card: Card = null
var _pile_preview_open: bool = false
var _settings_overlay: BattleSettingsOverlay = null


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
	player.piles_changed.connect(_on_player_piles_changed)
	back_menu_btn.pressed.connect(_on_back_menu_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	_setup_nav_button(back_menu_btn)
	_setup_nav_button(settings_btn)

	# 按钮点击事件
	end_turn_btn.pressed.connect(_on_end_turn_pressed)
	draw_pile_button.pressed.connect(_on_draw_pile_pressed)
	discard_pile_button.pressed.connect(_on_discard_pile_pressed)
	replay_btn.show() 
	# 点击就重置场景
	replay_btn.pressed.connect(func():
		var gm = get_tree().current_scene as GameManager
		if gm:
			gm.reset_game()
	)
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


func _on_player_piles_changed(draw_count: int, discard_count: int) -> void:
	draw_pile_button.set_card_count(draw_count)
	discard_pile_button.set_card_count(discard_count)


func start_target_selection(card: Card) -> void:
	if not BattleManager.is_active or BattleManager.active_character != BattleManager.player:
		return
	_pending_card = card
	_selecting_target = true
	print("请选择卡牌 [" + card.card_name + "] 的目标")
	# 高亮所有合法目标
	highlight_valid_targets(card, BattleManager.player)


func _input(event: InputEvent) -> void:
	## 处理目标选择相关的输入
	if _pile_preview_open:
		return
	if not _selecting_target:
		return
	
	# 右键或 ESC 取消选择
	if event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
		print("取消目标选择")
		exit_target_selection()
		get_viewport().set_input_as_handled()
		return
	
	# 左键点击选择目标
	var is_left_mouse_pressed: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if is_left_mouse_pressed and _pending_card:
		var click_pos = get_viewport().get_mouse_position()
		var target = _get_character_at_position(click_pos)
		if target and BattleManager.is_valid_target(_pending_card, BattleManager.player, target):
			# 打出卡牌
			AudioManager.play_sfx("card_play")
			BattleManager.request_play_card(_pending_card, BattleManager.player, target)
			refresh_all_info()
			exit_target_selection()
			get_viewport().set_input_as_handled()
		else:
			exit_target_selection()


func _get_character_at_position(pos: Vector2) -> Character:
	## 根据屏幕坐标查找角色
	var max_distance = Settings.ui_design_character_click_radius
	for child in BattleManager.get_all_character():
		if child.is_dead:
			continue
		if not child.world_ui:
			continue
		# 使用 world_ui 的全局位置作为点击判定中心
		var char_pos = child.world_ui.global_position
		if char_pos.distance_to(pos) <= max_distance:
			return child
	return null


func highlight_valid_targets(card: Card, user: Character) -> void:
	# 遍历所有场上的角色，根据 is_valid_target 结果设置高亮
	for row in BattleManager.position_rows.values():
		for child in row.get_children():
			if child is Character and not child.is_dead:
				if BattleManager.is_valid_target(card, user, child):
					# 添加高亮效果
					AnimationService.add_highlight(child)


func exit_target_selection() -> void:
	_selecting_target = false
	_pending_card = null
	_remove_all_highlights()


func _remove_all_highlights() -> void:
	for c in BattleManager.get_all_character():
		AnimationService.remove_highlight(c)


func refresh_all_info() -> void:
	## 界面刷新逻辑
	# 更新玩家文本
	player_info.text = "【玩家】\n血量: %d/%d\n格挡: %d\n能量: %d/%d" % [
		player.health, player.health_max, player.block, player.energy, player.max_energy
	]

	if energy_label:
		energy_label.text = "%d/%d" % [player.energy, player.max_energy]
	_on_player_piles_changed(player.draw_pile.size(), player.discard_pile.size())
		
	# 更新敌人信息
	var enemy = _get_first_enemy()
	if enemy:
		enemy_info.text = "【敌人】\n血量: %d/%d\n格挡: %d\n意图: %s (%d)" % [
			enemy.health, enemy.health_max, enemy.block, enemy.intent_type, enemy.intent_value
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
	for child in hand_container.get_children():
		child.queue_free()

	for i in range(player.hand.size()):
		var card = player.hand[i]
		var card_ui = card_display_scene.instantiate()
		card_ui.set_card(card)
		card_ui.card_pressed.connect(_on_card_pressed)
		hand_container.add_child(card_ui)


func _on_card_pressed(card: Card) -> void:
	## 卡牌被点击时的处理逻辑
	if not _can_play_card(card):
		return
	
	AudioManager.play_sfx("card_play")
	
	# SELF 类型的卡牌直接自动以自己为目标
	if card.target_type == GlobalEnums.TargetType.SELF:
		if BattleManager.is_valid_target(card, player, player):
			BattleManager.request_play_card(card, player, player)
			refresh_all_info()
		return
	
	# 其他类型进入目标选择模式
	start_target_selection(card)


func _can_play_card(card: Card) -> bool:
	## 检查卡牌是否可以被打出
	if _selecting_target:
		return false
	if not BattleManager.is_active:
		return false
	if BattleManager.active_character != player:
		return false
	if not player.hand.has(card):
		return false
	if not player.is_energy_enough(card):
		return false
	return true


func _on_end_turn_pressed() -> void:
	## 按钮交互
	if BattleManager.active_character == player:
		player.end_turn()
		refresh_all_info()


func _on_draw_pile_pressed() -> void:
	_show_pile_preview("抽牌堆", player.draw_pile)


func _on_discard_pile_pressed() -> void:
	_show_pile_preview("弃牌堆", player.discard_pile)


func _show_pile_preview(title: String, cards: Array) -> void:
	if not deck_preview_overlay_scene:
		return
	var preview := deck_preview_overlay_scene.instantiate() as DeckPreviewOverlay
	_pile_preview_open = true
	preview.tree_exited.connect(func(): _pile_preview_open = false)
	add_child(preview)
	preview.show_pile(title, cards)


func _process(_delta: float) -> void:
	if BattleManager.can_next_turn:
		refresh_all_info()


func _get_first_enemy() -> Monster:
	## 辅助函数：获取第一个存活敌人
	for child in BattleManager.position_rows[GlobalEnums.PositionRow.ENEMY].get_children():
		if child is Monster and not child.is_dead:
			return child
	return null


func _on_back_menu_pressed() -> void:
	# 切换回主菜单场景
	get_tree().change_scene_to_file("res://scenes/ui/menu.tscn")


func _on_settings_pressed() -> void:
	if not settings_overlay_scene:
		return
	if _settings_overlay and is_instance_valid(_settings_overlay):
		return
	if _selecting_target:
		exit_target_selection()
	_settings_overlay = settings_overlay_scene.instantiate() as BattleSettingsOverlay
	add_child(_settings_overlay)
	_settings_overlay.closed.connect(func(): _settings_overlay = null)
	get_tree().paused = true


func _setup_nav_button(button: Button) -> void:
	button.mouse_entered.connect(func():
		button.pivot_offset = button.size * 0.5
		button.modulate = Color(1.15, 1.15, 1.15, 1.0)
		button.scale = Vector2(1.05, 1.05)
	)
	button.mouse_exited.connect(func():
		button.modulate = Color.WHITE
		button.scale = Vector2.ONE
	)
	
	
func show_reward_and_wait(reward_ids: Array[String], player_state: PlayerState) -> Signal:
	var reward_scene = preload("res://scenes/ui/reward_scene.tscn").instantiate()
	add_child(reward_scene)
	return reward_scene.setup_rewards_and_wait(reward_ids, player_state)
