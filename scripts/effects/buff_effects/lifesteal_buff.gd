class_name LifestealBuff
extends BuffResource
## 吸血增幅：赋予伤害卡牌回复生命的能力

@export var heal_value: int = 5 # 每次造成的吸血量


func apply_to_card(card: Card) -> Card:
	var has_damage = false
	for effect in card.effects:
		if effect is DamageEffect:
			has_damage = true
			break
			
	# 如果这张牌有伤害，就它加一个治疗效果
	if has_damage:
		var extra_heal = HealEffect.new()
		extra_heal.base_amount = heal_value
		card.effects.append(extra_heal)
		print("吸血附魔触发！为该卡牌临时追加了 ", heal_value, " 点治疗效果！")
		
	return card
