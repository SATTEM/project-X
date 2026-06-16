class_name HealEffect
extends EffectResource

@export var base_amount: int
@export var heal_self: bool = false  # 为true治疗user，为false治疗target


func apply(_user: Character, target: Character) -> void: 
	## 将效果应用到目标上
	var target_node = _user if heal_self else target
	if target_node and target_node.has_method("heal"):
		target_node.heal(base_amount)


func get_value():
	return base_amount
