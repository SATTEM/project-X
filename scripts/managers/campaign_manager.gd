extends Node

var campaign: Array[LevelResource] = []
var _loop_count: int = 0  ## 无尽模式循环计数器


func get_default_campain(loop_index: int = 0) -> Array[LevelResource]:
	## 得到默认的战役模板
	## loop_index: 无尽模式循环编号，0=首轮，1=第二轮...
	var fallback_enemy_id := _pick_registered_enemy(Settings.easy_enemy_pool)

	# 每轮循环以休息关开头，供玩家选择难度
	var rest0 = RestLevel.new()
	rest0.level_name = "休息" + ("+" if loop_index > 0 else "")
	rest0.level_type = "rest"

	var battle1 = BattleLevel.new()
	battle1.level_name = "战斗1" + ("+" if loop_index > 0 else "")
	battle1.level_type = "battle"
	battle1.set_enemies([fallback_enemy_id])
	battle1.reward_gold = 50

	var rest1 = RestLevel.new()
	rest1.level_name = "休息1" + ("+" if loop_index > 0 else "")
	rest1.level_type = "rest"

	var battle2 = BattleLevel.new()
	battle2.level_name = "战斗2" + ("+" if loop_index > 0 else "")
	battle2.level_type = "battle"
	battle2.set_enemies([fallback_enemy_id])
	battle2.reward_gold = 60

	var shop = preload("res://assets/resources/shops/shop_1.tres")
	shop.level_name = "商店"
	shop.level_type = "shop"

	var rest2 = RestLevel.new()
	rest2.level_name = "休息2" + ("+" if loop_index > 0 else "")
	rest2.level_type = "rest"

	var battle3 = BattleLevel.new()
	battle3.level_name = "战斗3" + ("+" if loop_index > 0 else "")
	battle3.level_type = "battle"
	battle3.set_enemies([fallback_enemy_id])
	battle3.reward_gold = 70

	return [rest0, battle1, rest1, battle2, shop, rest2, battle3]


func _pick_registered_enemy(configured_pool: Array[String]) -> String:
	var registered_ids := MonsterLibrary.get_all_monster_ids()
	var valid_pool: Array[String] = []
	for monster_id in configured_pool:
		if registered_ids.has(monster_id):
			valid_pool.append(monster_id)
	if valid_pool.is_empty():
		return "base"
	return valid_pool.pick_random()


func init_campaign():
	_loop_count = 0
	campaign = get_default_campain(0)


func new_loop():
	## 将默认战役模板拼接到当前战役末尾（无尽模式）
	_loop_count += 1
	print("无尽模式——进入第 ", _loop_count + 1, " 轮战役循环")
	campaign.append_array(get_default_campain(_loop_count))


func get_current_level(player_state: PlayerState) -> LevelResource:
	if not player_state:
		return null
	var idx = player_state.current_level_index
	if idx < campaign.size():
		return campaign[idx]
	return null


func get_counted_layer_number(player_state: PlayerState) -> int:
	if not player_state or campaign.is_empty():
		return 1
	var current_index := clampi(player_state.current_level_index, 0, campaign.size() - 1)
	var counted_layers := 0
	for index in range(current_index + 1):
		if campaign[index].level_type != "rest":
			counted_layers += 1
	return maxi(counted_layers, 1)


func advance_to_next_level(player_state: PlayerState):
	if not player_state:
		return
	print("推进前索引：", player_state.current_level_index)
	player_state.current_level_index += 1
	print("推进后索引：", player_state.current_level_index)
	SaveManager.save_player_state(player_state)


func get_next_battle_level(player_state: PlayerState) -> BattleLevel:
	if not player_state:
		return null
	var start_idx = player_state.current_level_index + 1
	for i in range(start_idx, campaign.size()):
		if campaign[i] is BattleLevel:
			return campaign[i]
	return null


func is_boss_rest(player_state: PlayerState) -> bool:
	## 每轮商店后的休息区固定提供 Boss 挑战，避免首领完全依赖随机抽取。
	if not player_state or campaign.is_empty():
		return false
	var current_index := player_state.current_level_index
	if current_index <= 0 or current_index >= campaign.size():
		return false
	var current_level := campaign[current_index]
	var previous_level := campaign[current_index - 1]
	return current_level.level_type == "rest" and previous_level.level_type == "shop"


func has_next_level(player_state: PlayerState) -> bool:
	if not player_state:
		return false
	return player_state.current_level_index < campaign.size()
