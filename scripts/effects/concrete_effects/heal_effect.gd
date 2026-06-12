class_name HealEffect
extends EffectResource

@export var base_amount: int


func apply(_user: Character, target: Character) -> void: 
	## 将效果应用到目标上
	if target and target.has_method("heal"):
		target.heal(base_amount)

func get_value():
	return base_amount
