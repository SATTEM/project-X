class_name HealEffect
extends EffectResource

@export var base_amount: int


func apply(user: Character, _target: Character) -> void: 
	## 将效果应用到user, target上
	user.health += base_amount
