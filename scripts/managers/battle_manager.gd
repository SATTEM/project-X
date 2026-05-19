extends Node2D
## 战斗管理器脚本

# 动画信号
signal card_play_requested(card: Card, source: Character, target: Character)
signal damage_display_requested(character: Character, amount: int)
signal block_display_requested(character: Character, amount: int)
signal heal_display_requested(character: Character, amount: int)
signal call_refresh()
signal battle_finished(result: Dictionary)

# 通过注册来获取卡牌和角色的引用
# 战斗要素
var player: Player
var turn_queue: Array[Character]
var active_character: Character = null
var current_character_index: int = 0
var current_player_state: PlayerState = null
# 战斗信息和标志
var battle_over: bool = false
var turn_count: int = 0
var can_next_turn: bool = false
var is_active: bool = false
var current_allies_count: int = 0
var current_enemies_count: int = 0
# 容器
var card_container: Node2D
var position_rows: Dictionary[GlobalEnums.PositionRow, Node2D] = {}


func _ready() -> void:
	## 初始化战斗管理器
	card_container = Node2D.new()
	add_child(card_container)
	for row in GlobalEnums.PositionRow.values():
		var row_node = Node2D.new()
		row_node.name = str(row)
		add_child(row_node)
		position_rows[row] = row_node
	# 动态调整行位置
	_update_rows_position()
	# 监听窗口大小变化
	get_tree().root.size_changed.connect(_on_window_resized)


func _on_window_resized():
	_update_rows_position()


func _on_character_died(character: Character) -> void:
	## 当有角色死亡时调用此方法
	## 检查是否为玩家，是则失败，否则胜利
	if battle_over:
		return
	if character == player:
		AudioManager.play_sfx("defeat")
		print("You died!")
		_end_battle(false)
	else:
		var idx = turn_queue.find(character)
		if idx != -1:
			turn_queue.remove_at(idx)
			if idx <= current_character_index and current_character_index > 0:
				current_character_index -= 1
			if character.is_ally:
				current_allies_count -= 1
			else:
				current_enemies_count -= 1
		if character == active_character:
			active_character = null
			if current_character_index >= turn_queue.size():
				current_character_index = 0
			can_next_turn = true # 使回合继续
		# 记录它所在的行，删除节点后需要重排列
		var dead_row = character.current_row
		character.queue_free()
		# 重新排列该行
		call_deferred("_arrange_row", dead_row)
	
	if current_enemies_count <= 0:
		AudioManager.play_sfx("victory")
		print("You win")
		_end_battle(true)
	return


func _on_character_turn_ended(_character: Character) -> void:
	## 角色回合结束，标记可以进入下一个回合
	if battle_over:
		return
	can_next_turn = true	
	return


func _process(_delta: float) -> void:
	## 每一帧检查按帧变化的逻辑标志
	if can_next_turn and not battle_over:
		if active_character:
			print(active_character.name + "的回合结束")
		current_character_index = (current_character_index + 1) % turn_queue.size()
		can_next_turn = false
		while (current_character_index < turn_queue.size() 
				and turn_queue[current_character_index].is_dead):
			turn_queue.remove_at(current_character_index)
		if turn_queue.is_empty():
			return
		start_character_turn(turn_queue[current_character_index])


func _update_rows_position():
	## 更新行节点以及内部节点位置
	var viewport_size = get_viewport_rect().size
	var h = Settings.ui_design_height
	var scale_y = viewport_size.y / h
	# 设置行节点position.y
	position_rows[GlobalEnums.PositionRow.ENEMY].position.y = h * 0.17 * scale_y
	position_rows[GlobalEnums.PositionRow.FRONT].position.y = h * 0.39 * scale_y
	position_rows[GlobalEnums.PositionRow.PLAYER].position.y = h * 0.57 * scale_y

	# 每一行重新排列子单位
	for row in GlobalEnums.PositionRow.values():
		_arrange_row(row)


func _arrange_row(row: GlobalEnums.PositionRow):
	## 重排列某行单位
	var row_node = position_rows[row]
	var units: Array[Node2D] = []
	for child in row_node.get_children():
		if child is Character and not child.is_dead:
			units.append(child as Node2D)
	if units.size() == 0:
		return
	
	var scale_x = get_viewport_rect().size.x / Settings.ui_design_width
	# 在设计分辨率下计算每个单位的 X 坐标
	var design_total_width = (units.size() - 1) * Settings.ui_design_monster_spacing
	var design_start_x = (Settings.ui_design_width - design_total_width) / 2.0
	
	for i in units.size():
		var design_x = design_start_x + i * Settings.ui_design_monster_spacing
		units[i].position.x = design_x * scale_x
		units[i].position.y = 0 # 采用行节点坐标


func register_character(character: Character) -> void:
	## 注册角色，并连接共有信号
	if character is Player:
		player = character
		turn_queue.push_front(character)
	elif character.is_ally:
		var insert_index = 1
		for i in range(1, turn_queue.size()):
			if turn_queue[i].is_ally:
				insert_index = i + 1
			else:
				break
		turn_queue.insert(insert_index, character)
		current_allies_count += 1
	else:
		turn_queue.push_back(character)
		current_enemies_count += 1
	# 连接信号
	# 角色死亡
	if not character.character_died.is_connected(_on_character_died):
		character.character_died.connect(_on_character_died)
	# 角色结束回合
	if not character.turn_ended.is_connected(_on_character_turn_ended):
		character.turn_ended.connect(_on_character_turn_ended)
	# 特效转发
	if not character.damage_display.has_connections():
		character.damage_display.connect(func(c: Character, a: int): damage_display_requested.emit(c, a))
		character.block_display.connect(func(c: Character, a: int): block_display_requested.emit(c, a))
		character.heal_display.connect(func(c: Character, a: int): heal_display_requested.emit(c, a))
	print("Registered: " + character.name)
	return


func start_battle(aPlayer: Player, enemies: Array[Monster], player_state: PlayerState = null):
	## 战斗初始化方法
	## 注册战斗开始时就存在的玩家、敌人
	## 并完成对应初始化
	# 清理逻辑
	turn_queue.clear()      # 清空上局的死人队列
	battle_over = false     # 重置战斗结束标志
	turn_count = 0          # 回合数归零重计
	can_next_turn = false   # 锁住回合流转逻辑
	is_active = false
	active_character = null
	current_allies_count = 0
	current_enemies_count = 0
	_clear_card_container()
	# 清理所有行上的旧单位
	for row in position_rows:
		for child in position_rows[row].get_children():
			position_rows[row].remove_child(child)
			if child != aPlayer:
				child.queue_free()

	# 处理玩家
	# 将玩家节点移动到PLAYER行下
	if aPlayer.get_parent():
		aPlayer.get_parent().remove_child(aPlayer)
	player = aPlayer
	current_player_state = player_state
	player.battle_init(player_state)
	register_character(player)
	position_rows[GlobalEnums.PositionRow.PLAYER].add_child(player)
	
	# 处理敌人，挂载到ENEMY行中并注册
	for enemy in enemies:
		position_rows[GlobalEnums.PositionRow.ENEMY].add_child(enemy)
		register_character(enemy)
		enemy.init()
	
	is_active = true
	current_character_index = 0
	# 全部注册完后刷新行布局
	_update_rows_position()
	start_character_turn(turn_queue[current_character_index])
	return


func start_battle_from_state(aPlayer: Player, player_state: PlayerState, enemies: Array[Monster]) -> void:
	## 玩家从已有状态开始战斗
	start_battle(aPlayer, enemies, player_state)


func start_character_turn(character: Character) -> void:
	## 开始某个角色的回合，若为玩家则等待输入
	if battle_over:
		return
	active_character = character
	if character is Player:
		# 回合数加一
		turn_count += 1
	character.start_turn()
	if character is Player:
		# 玩家的操作逻辑在Player内执行
		pass
	else:
		character.end_turn()


func summon_minion(monster_id: String) -> bool:
	## 根据ID召唤一个随从
	if not _can_summion():
		return false
	var target_row = GlobalEnums.PositionRow.FRONT
	var row_node = position_rows[target_row]
	var minion = MonsterLibrary.create_monster(monster_id)
	if not minion:
		printerr("Fail to create minion: ", monster_id)
		return false
	# 初始化
	minion.is_ally = true
	row_node.add_child(minion)
	minion.init()
	register_character(minion)
	# 重排位置
	_arrange_row(target_row)
	return true


func request_play_card(
		card: Card,
		source: Character,
		target: Character
	) -> bool:
	## 请求打出一张卡牌， 所有规则检查集中在这里
	# 排除非法场景
	if not is_active:
		return false
	if source.is_dead or target.is_dead:
		return false
	if source is Player and not (source as Player).is_energy_enough(card.cost):
		return false
	# 扣费
	if source is Player:
		(source as Player).spend_energy(card.cost)
	# 卡牌从手牌移除
	if source.hand.has(card):
		source.hand.erase(card)
	# 如果角色有弃牌堆，弃掉
	if source.has_method("discard"):
		source.discard(card)
	# 发射信号
	card_play_requested.emit(card, source, target)
	# 执行结算
	card.play_card_on_target(source, target)
	return true


func get_card_target() -> Character:
	## 选择卡牌打击对象
	## 玩家和随从打击敌人
	## 敌人先尝试打击前排，前排没有单位则打击玩家
	if not active_character:
		return null
	var attacker = active_character
	# 玩家: 在ENEMY或FRONT行找一个活着的敌人
	# 后续改为玩家自选
	if attacker is Player:
		for row in [GlobalEnums.PositionRow.ENEMY, GlobalEnums.PositionRow.FRONT]:
			for child in position_rows[row].get_children():
				if child is Monster and not child.is_ally and not child.is_dead:
					return child
		return null
	# 怪物
	if attacker is Monster:
		# 己方随从攻击ENEMY行敌人
		if attacker.is_ally:
			for child in position_rows[GlobalEnums.PositionRow.ENEMY].get_children():
				if child is Monster and not child.is_ally and not child.is_dead:
					return child
			return null

		# 敌方单位优先攻击FRONT行
		else:
			# 先找FRONT行的友方单位
			for child in position_rows[GlobalEnums.PositionRow.FRONT].get_children():
				if child is Monster and child.is_ally and not child.is_dead:
					return child
			# 如果前线没人，就打玩家
			if player and not player.is_dead:
				return player
			return null

	return null


func _can_summion() -> bool:
	## 检查是否能召唤
	# 随从固定出生在FRONT行
	var target_row = GlobalEnums.PositionRow.FRONT
	var row_node = position_rows[target_row]
	# 检查该行上限
	var count_in_row = 0
	for child in row_node.get_children():
		if child is Monster and not child.is_dead:
			count_in_row += 1
	if count_in_row >= Settings.position_row_front_count:
		print("前排已满，无法召唤")
		return false
	return true


func end_game() -> void:
	## 结束战斗
	_end_battle(false)
	return


func _end_battle(victory: bool) -> void:
	if battle_over:
		return
	battle_over = true
	is_active = false
	can_next_turn = false
	active_character = null
	call_refresh.emit()
	var selected = ""
	if victory:
		# 如果是最后一场战斗，则结束后不弹奖励界面
		var total_battles = CampaignManager.get_total_battles()
		var is_last_battle = (current_player_state.battles_completed + 1) >= total_battles
		if not is_last_battle:
			var candidates = _build_rewards(true)
			if candidates.size() > 0:
				var battle_ui = get_tree().current_scene.get_node("UIContainer/BattleUI")
				if battle_ui:
					selected = await battle_ui.show_reward_and_wait(candidates, current_player_state)
	var result = {
		"victory": victory,
		"remaining_hp": player.health if player else 0,
		"rewards": [selected] if selected != "" else [],
	}
	battle_finished.emit(result)
	print("Game end...")


func _build_rewards(victory: bool) -> Array[String]:
	## 生成奖励候选卡牌列表
	if not victory:
		return []
	# 获取本局游戏已经拥有的卡牌ID列表
	var owned = current_player_state.deck_ids if current_player_state else []
	# 获取全局永久解锁的卡牌ID列表
	var unlocked = GlobalUnlockManager.get_all_unlocked()
	print("owned:", owned, " unlocked:", unlocked)
	# 候选池=已解锁的牌-本局已经拥有的牌
	var candidates = unlocked.filter(func(id): return not owned.has(id))
	# 如果拥有所有已解锁的牌，允许重复获得已有卡牌
	if candidates.is_empty():
		candidates = GlobalUnlockManager.get_all_unlocked()
	print("candidates:", candidates)
	candidates.shuffle()
	var result = candidates.slice(0, 3)
	return result


func _clear_card_container() -> void:
	if not card_container:
		return
	for child in card_container.get_children():
		child.queue_free()
