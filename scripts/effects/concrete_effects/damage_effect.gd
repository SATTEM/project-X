class_name DamageEffect
extends EffectResource

@export var base_amount: int


func apply(_user: Character, target: Character) -> void:
	## 受击扣血：先扣格挡值,格挡值减少，若为0则再减少角色血量
	target.take_damage(base_amount)
