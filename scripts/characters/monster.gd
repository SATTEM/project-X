class_name Monster
extends Character

signal intent_changed(type: String, value: int)

var intent_type: String = "attack"
var intent_value: int = 0
var energy_slots: Dictionary[GlobalEnums.Element, int] = {GlobalEnums.Element.WATER: 1}
var energy_slots_max: Dictionary[GlobalEnums.Element, int] = {GlobalEnums.Element.WATER: 2}
@onready var body_sripte: Sprite2D = $BodySprite
@onready var intent_icon: Sprite2D = $IntentIcon


func choose_intent(round_index: int):
	## 选择意图，目前按照固定策略循环
	if round_index % 2 == 1:
		intent_type = "attack"
		intent_value = 6
	else:
		intent_type = "defend"
		intent_value = 5


func execute_intent():
	## 执行意图
	if intent_type == "attack" and energy_slots[GlobalEnums.Element.WATER] > 0:
		BattleManager.player.take_damage(intent_value)
		print("Player get hitted!")
	elif intent_type == "defend" and energy_slots[GlobalEnums.Element.WATER] > 0:
		# 没写完格挡前的实现：直接加血
		health += intent_value
		print("Monster get heal!")


func start_turn() -> void:
	# 根据回合数选择意图并广播
	choose_intent(BattleManager.turn_count)
	intent_changed.emit(intent_type, intent_value)
	# 根据意图切换意图图标
	if intent_type == "attack":
		intent_icon.texture = load("res://assets/art/intents/attack.png")
	else:
		intent_icon.texture = load("res://icon.svg")
	# 执行意图并结束回合
	execute_intent()
	turn_ended.emit(self)
