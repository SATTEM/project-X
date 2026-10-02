class_name SummonEffect
extends EffectResource

@export var monster_id: String = "base"


func apply(user: Character, _target: Character) -> void:
	# 召唤者必须是玩家
	if not user is Player:
		printerr("Only player can summon monster!")
		return
	if monster_id.is_empty():
		printerr("Summon card has no bound monster!")
		return
	if not BattleManager._can_summion():
		return
	BattleManager.summon_minion(monster_id)
	

func get_value():
	return 1
