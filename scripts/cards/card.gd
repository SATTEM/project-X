class_name Card
extends Node2D
## 卡牌脚本

signal played(card_instance: Card)

@export var card_resource: CardResource
var effects: Array[EffectResource] = []
var card_name: String:
	get:
		return card_resource.card_name
var cost: int:
	get:
		return card_resource.cost


func _ready() -> void:
	BattleManager.register_card(self)
	return


func play_card_on_target(user: Character, target: Character) -> void:
	print(user.name + " played card: [" + card_name+"] at: [" + target.name + "]")
	for effect in effects:
		effect.apply(user, target)
	return


func play() -> void:
	played.emit(self)

#func clicked():
	#print("你点击了卡牌。")				
