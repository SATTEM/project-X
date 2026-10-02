class_name PlayerState
extends Resource
## 玩家状态和存档类

@export var save_version: int = 2
@export var max_hp: int = 100
@export var current_hp: int = 100
@export var deck_ids: Array[String] = []
@export var summon_bindings: Array[String] = []
@export var current_node_id: String = ""
@export var battles_completed: int = 0
@export var current_level_index: int = 0
@export var gold: int = 100


func reset_to_defaults(default_deck_ids: Array[String], max_hp_value: int = 100) -> void:
	## 重置为初始存档
	max_hp = max_hp_value
	current_hp = max_hp_value
	deck_ids = default_deck_ids.duplicate()
	summon_bindings.clear()
	_ensure_summon_bindings()
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
					add_card_to_run_deck(card_id)
	print("查看牌库：")
	for id in deck_ids:
		print("  - ", id)

func add_card_to_run_deck(card_id: String) -> void:
	## 获取卡牌奖励
	_ensure_summon_bindings()
	deck_ids.append(card_id)
	summon_bindings.append(CardLibrary.get_default_summon_binding(card_id))
	print(" 已将卡牌添加到本局牌组: ", card_id)


func remove_card_from_run_deck(card_id: String) -> bool:
	## 商店删牌服务调用
	# erase 只会删除找到的第一张，符合删牌规则
	var card_index := deck_ids.find(card_id)
	if card_index != -1:
		_ensure_summon_bindings()
		deck_ids.remove_at(card_index)
		summon_bindings.remove_at(card_index)
		print(" 已从本局牌组移除卡牌: ", card_id)
		return true
	print(" 牌组中不存在该卡牌: ", card_id)
	return false


func get_summon_binding(deck_index: int) -> String:
	_ensure_summon_bindings()
	if deck_index < 0 or deck_index >= summon_bindings.size():
		return ""
	return summon_bindings[deck_index]


func set_summon_binding(deck_index: int, monster_id: String) -> bool:
	_ensure_summon_bindings()
	if deck_index < 0 or deck_index >= deck_ids.size():
		return false
	if CardLibrary.get_default_summon_binding(deck_ids[deck_index]).is_empty():
		return false
	summon_bindings[deck_index] = monster_id
	return true


func _ensure_summon_bindings() -> void:
	while summon_bindings.size() < deck_ids.size():
		var card_id := deck_ids[summon_bindings.size()]
		summon_bindings.append(CardLibrary.get_default_summon_binding(card_id))
	if summon_bindings.size() > deck_ids.size():
		summon_bindings.resize(deck_ids.size())
