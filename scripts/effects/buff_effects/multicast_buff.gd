class_name MulticastBuff
extends BuffResource
## 连击增幅：使卡牌里的伤害效果触发两次


func apply_to_card(card: Card) -> Card:
	var new_effects: Array[EffectResource] = []
	var triggered = false
	
	# 遍历原有的效果
	for effect in card.effects:
		new_effects.append(effect) # 保留原有效果
		
		# 如果遇到伤害效果，再塞一个一模一样的进去！
		if effect is DamageEffect or effect is MultiHitDamageEffect:
			new_effects.append(effect.duplicate(true))
			triggered = true
			
	if triggered:
		card.effects = new_effects
		print("回响符文触发！卡牌中的伤害效果已复制，将独立结算两次。")
		
	return card
