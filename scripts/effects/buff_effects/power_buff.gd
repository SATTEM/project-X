class_name PowerBuff
extends BuffResource
## 力量增幅 Buff：使打出的所有伤害牌数值提升

@export var bonus_damage: int = 3 # 增加的攻击力数值

func apply_to_card(card: Card) -> Card:
	## 拦截并修改临时卡牌
	for effect in card.effects:
		# 识别该效果是不是伤害效果
		if effect is DamageEffect:
			# 核心：修改替身卡牌里的伤害数值！
			effect.base_amount += bonus_damage
			print("力量增幅触发！该卡牌的伤害被提升了 ", bonus_damage, " 点，目前伤害为: ", effect.base_amount)
			
	return card
