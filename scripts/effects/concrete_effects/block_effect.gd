class_name BlockEffect
extends EffectResource

@export var base_amount: int


func apply(user: Character, _target: Character) -> void:
	## 将效果应用到user, target上
	user.add_block(base_amount)


func get_value():
	return base_amount
