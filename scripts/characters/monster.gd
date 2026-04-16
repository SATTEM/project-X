class_name Monster
extends Character

signal intent_changed(type: String, value: int)

var intent_type: String = "attack"
var intent_value: int = 0
var energy_slots: Dictionary[GlobalEnums.Element, int] = {GlobalEnums.Element.WATER: 1}
var energy_slots_max: Dictionary[GlobalEnums.Element, int] = {GlobalEnums.Element.WATER: 2}

func choose_intent(round_index: int):
	## 选择意图，目前按照固定策略循环
	if round_index % 2 == 0:
		intent_type = "attack"
		intent_value = 6
	else:
		intent_type = "defend"
		intent_value = 5


func execute_intent():
	## 执行意图
	if intent_type == "attack" and energy_slots[GlobalEnums.Element.WATER] > 0:
		BattleManager.player.take_damage(intent_value)
	elif intent_type == "defend" and energy_slots[GlobalEnums.Element.WATER] > 0:
		# 没写完格挡前的实现：直接加血
		health += intent_value


func start_turn() -> void:
	choose_intent(BattleManager.turn_count)
	intent_changed.emit(intent_type, intent_value)
	execute_intent()
	turn_ended.emit()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	BattleManager.register_character(self, false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
