class_name Card
extends Node2D
## 卡牌脚本

@export var card_resource: CardResource
var effects: Array[EffectResource] = []
var card_name: String:
	get:
		return card_resource.card_name
var cost: int:
	get:
		return card_resource.cost
var target_type: GlobalEnums.TargetType:
	get:
		return card_resource.target_type


func play_card_on_target(user: Character, target: Character) -> void:
	print(user.name + " played card: [" + card_name+"] at: [" + target.name + "]")
	for effect in effects:
		effect.apply(user, target)
	return
