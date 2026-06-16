extends Node

var campaign: Array[LevelResource] = []

func init_campaign():
	var battle1 = BattleLevel.new()
	battle1.level_name = "战斗1"
	battle1.level_type = "battle"
	battle1.set_enemies(["base"])
	battle1.reward_gold = 50
	
	var rest1 = RestLevel.new()
	rest1.level_name = "休息1"
	rest1.level_type = "rest"
	
	var battle2 = BattleLevel.new()
	battle2.level_name = "战斗2"
	battle2.level_type = "battle"
	battle2.set_enemies([])
	
	var shop = preload("res://assets/resources/shops/shop_1.tres")
	shop.level_name = "商店"
	shop.level_type = "shop"

	var rest2 = RestLevel.new()
	rest2.level_name = "休息2"
	rest2.level_type = "rest"
	
	var battle3 = BattleLevel.new()
	battle3.level_name = "战斗3"
	battle3.level_type = "battle"
	battle3.set_enemies([])
	
	campaign = [battle1, rest1, battle2, shop, rest2, battle3]


func get_current_level(player_state: PlayerState) -> LevelResource:
	if not player_state:
		return null
	var idx = player_state.current_level_index
	if idx < campaign.size():
		return campaign[idx]
	return null


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


func has_next_level(player_state: PlayerState) -> bool:
	if not player_state:
		return false
	return player_state.current_level_index < campaign.size()
