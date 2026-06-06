class_name FIFOStrategy
extends MonsterPlayStrategy
## 先入先出策略
## 按照抽到的顺序尝试打牌，遍历所有意图卡牌，找到第一个可以打出（有足够能量且存在合法目标）的卡牌


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
