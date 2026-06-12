class_name SelfishStrategy
extends MonsterPlayStrategy
## 自私策略
## 选牌优先级：SELF > ENEMY > ANY > ALLY > MONSTER


func select_card(hand: Array[ElementCard], _monster: Monster) -> ElementCard:
	## 按自私倾向选择卡牌
	var priority = [
		GlobalEnums.TargetType.SELF,
		GlobalEnums.TargetType.ENEMY,
		GlobalEnums.TargetType.ANY,
		GlobalEnums.TargetType.ALLY,
		GlobalEnums.TargetType.MONSTER,
	]
	for target_type in priority:
		for card in hand:
			if card.target_type == target_type:
				return card
	return hand.front() if not hand.is_empty() else null


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
