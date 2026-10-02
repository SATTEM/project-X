class_name CostReductionBuff
extends BuffResource
## 减费增幅：使该角色打出的下一张/几张牌耗能减少

@export var cost_reduction: int = 1


func apply_to_card(card: Card) -> Card:
	## 卡牌克隆时候使用了深拷贝, 所以直接修改克隆体的资源费用是绝对安全的，不会污染原牌库
	if card.card_resource:
		var original_cost = card.card_resource.cost
		# 确保费用不会扣成负数
		card.card_resource.cost = max(0, original_cost - cost_reduction)
		print("减费增幅触发！原费用 ", original_cost, "，现费用: ", card.card_resource.cost)
			
	return card
