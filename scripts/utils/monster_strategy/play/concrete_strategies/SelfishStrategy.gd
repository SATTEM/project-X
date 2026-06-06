class_name SelfishStrategy
extends MonsterPlayStrategy


func choose_target(card: Card, monster: Monster, all_characters: Array[Character]) -> Character:
	# 1. 如果卡牌目标类型是 SELF，直接返回自己
	if card.target_type == GlobalEnums.TargetType.SELF:
		return monster
	# 2. 否则优先打敌人（需通过合法性校验，含前排保护）
	for c in all_characters:
		if c.is_ally != monster.is_ally and not c.is_dead:
			if BattleManager.is_valid_target(card, monster, c):
				return c
	# 3. 没有敌人则打盟友
	for c in all_characters:
		if c.is_ally == monster.is_ally and c != monster and not c.is_dead:
			if BattleManager.is_valid_target(card, monster, c):
				return c
	return null
