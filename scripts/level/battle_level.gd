class_name BattleLevel
extends LevelResource

var enemies: Array[String] = []
var reward_gold: int = 50

func set_enemies(arr):
	enemies.clear()
	for id in arr:
		enemies.append(str(id))
