class_name SelflessStrategy
extends MonsterPlayStrategy
## 无私策略
## 优先对盟友打牌，再对敌人打牌，最后对自己打牌


static func _first_valid(card: Card, monster: Monster, list: Array[Character]) -> Character:
	## 从列表中查找第一个通过合法性校验的目标
	for c in list:
		if BattleManager.is_valid_target(card, monster, c):
			return c
	return null


func choose_target(card: Card, monster: Monster, all_characters: Array[Character]) -> Character:
	# 按优先级分类：盟友（不含自己）、敌人
	var allies: Array[Character] = []
	var enemies: Array[Character] = []
	for c in all_characters:
		if c.is_dead:
			continue
		if c.is_ally == monster.is_ally and c != monster:
			allies.append(c)
		elif c.is_ally != monster.is_ally:
			enemies.append(c)
	
	# 按 TargetType 匹配优先级
	match card.target_type:
		GlobalEnums.TargetType.SELF:
			if BattleManager.is_valid_target(card, monster, monster):
				return monster
		GlobalEnums.TargetType.ALLY:
			var t = _first_valid(card, monster, allies)
			if t: return t
		GlobalEnums.TargetType.ENEMY:
			var t = _first_valid(card, monster, enemies)
			if t: return t
		GlobalEnums.TargetType.MONSTER:
			for c in all_characters:
				if c is Monster and not c.is_dead \
						and BattleManager.is_valid_target(card, monster, c):
					return c
		GlobalEnums.TargetType.ANY:
			# 按策略优先级：盟友 > 敌人 > 自己
			var t = _first_valid(card, monster, allies)
			if t: return t
			t = _first_valid(card, monster, enemies)
			if t: return t
			if BattleManager.is_valid_target(card, monster, monster):
				return monster
	
	# 兜底：按策略优先级遍历
	var t = _first_valid(card, monster, allies)
	if t: return t
	t = _first_valid(card, monster, enemies)
	if t: return t
	if BattleManager.is_valid_target(card, monster, monster):
		return monster
	return null
