class_name PlayerState
extends Resource
## 玩家状态和存档类

@export var save_version: int = 1
@export var max_hp: int = 100
@export var current_hp: int = 100
@export var deck_ids: Array[String] = []
@export var current_node_id: String = ""
@export var battles_completed: int = 0
@export var current_level_index: int = 0
@export var gold: int = 100


func reset_to_defaults(default_deck_ids: Array[String], max_hp_value: int = 100) -> void:
	## 重置为初始存档
	max_hp = max_hp_value
	current_hp = max_hp_value
	deck_ids = default_deck_ids.duplicate()
	current_node_id = ""
	battles_completed = 0
	current_level_index = 0
	gold = 99


func apply_battle_result(result: Dictionary) -> void:
	## 从战斗结果更新状态
	if result.has("remaining_hp"):
		current_hp = clamp(int(result["remaining_hp"]), 0, max_hp)
	if result.get("victory", false):
		battles_completed += 1
	if result.has("rewards"):
		var rewards = result["rewards"]
		if rewards is Array:
			for card_id in rewards:
				if card_id is String:
					deck_ids.append(card_id)
	print("查看牌库：")
	for id in deck_ids:
		print("  - ", id)

func add_card_to_run_deck(card_id: String) -> void:
	## 获取卡牌奖励
	deck_ids.append(card_id)
	print(" 已将卡牌添加到本局牌组: ", card_id)


func remove_card_from_run_deck(card_id: String) -> bool:
	## 商店删牌服务调用
	# erase 只会删除找到的第一张，符合删牌规则
	if deck_ids.has(card_id):	
		deck_ids.erase(card_id)
		print(" 已从本局牌组移除卡牌: ", card_id)
		return true
	print(" 牌组中不存在该卡牌: ", card_id)
	return false
