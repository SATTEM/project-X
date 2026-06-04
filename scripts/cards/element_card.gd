class_name ElementCard
extends Card

# 选定的元素
var element: GlobalEnums.Element


static func build_from_card(card: Card, e: GlobalEnums.Element) -> ElementCard:
	var element_card: ElementCard = ElementCard.new()
	element_card.card_resource = card.card_resource
	element_card.effects = card.effects
	element_card.element = e
	return element_card
