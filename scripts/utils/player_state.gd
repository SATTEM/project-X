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
