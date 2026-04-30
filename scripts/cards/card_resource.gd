class_name CardResource
extends BaseCardFactory
## 卡牌资源脚本，作为资源和工厂

@export var card_name: String = "攻击"
@export var cost: int = 0
@export var effect_resources: Array[EffectResource]
@export var texture: Texture2D


func create_card() -> Card:
	## 具体创建卡牌方法
	var card = Card.new()
	card.card_resource = self
	card.effects.clear()
	for effect_resource in effect_resources:
		var new_effect = effect_resource.duplicate()
		card.effects.append(new_effect)
	return card
