extends Node
## 战役管理器，管理多场战斗的组合

var _battle_sequence: Array = [
	["base"],
	["base", "base"],
	["base"],
]


func has_next_battle(player_state: PlayerState) -> bool:
	## 判断是否还有下一场战斗，若有，则按照玩家现有状态进战
	if not player_state:
		return false
	return player_state.battles_completed < _battle_sequence.size()


func get_next_battle_monsters(player_state: PlayerState) -> Array[Monster]:
	## 获取下一战斗的怪物
	var result: Array[Monster] = []
	if not player_state or _battle_sequence.is_empty():
		return result
	var index = clamp(player_state.battles_completed, 0, _battle_sequence.size() - 1)
	var ids = _battle_sequence[index]
	for monster_id in ids:
		var monster = MonsterLibrary.create_monster(monster_id)
		if monster:
			result.append(monster)
	return result


func get_total_battles() -> int:
	return _battle_sequence.size()
