class_name SummonEffect
extends EffectResource

@export var monster_id: String


func apply(user: Character, _target: Character) -> void:
	# 召唤者必须是玩家
	if not user is Player:
		printerr("Only player can summon monster!")
		return
	BattleManager.summon_minion(monster_id)
	
