class_name FIFOStrategy
extends MonsterPlayStrategy
## 先入先出策略
## 按手牌顺序依次尝试打出


func select_card(hand: Array[ElementCard], _monster: Monster) -> ElementCard:
	return hand.front() if not hand.is_empty() else null


func choose_target(card: Card, monster: Monster, all_characters: Array[Character]) -> Character:
	# 对于单张卡牌，按队列顺序寻找合法目标：
	# 敌人 > 盟友 > 自己
	for c in all_characters:
		if c.is_dead:
			continue
		if c.is_ally != monster.is_ally:
			if BattleManager.is_valid_target(card, monster, c):
				return c
	for c in all_characters:
		if c.is_dead:
			continue
		if c.is_ally == monster.is_ally and c != monster:
			if BattleManager.is_valid_target(card, monster, c):
				return c
	if not monster.is_dead and BattleManager.is_valid_target(card, monster, monster):
		return monster
	return null
