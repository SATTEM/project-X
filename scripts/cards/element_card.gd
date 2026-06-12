class_name ElementCard
extends Card

# 选定的元素
var element: GlobalEnums.Element
# 该卡牌在怪物牌组循环中的出现回合
var appear_turn: int = 0


static func build_from_card(card: Card, e: GlobalEnums.Element, p_appear_turn: int = 0) -> ElementCard:
	var element_card: ElementCard = ElementCard.new()
	element_card.card_resource = card.card_resource
	element_card.effects = card.effects
	element_card.element = e
	element_card.appear_turn = p_appear_turn
	return element_card
