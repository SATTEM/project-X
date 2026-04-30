class_name DamageEffect
extends EffectResource

@export var base_amount: int


func apply(_user: Character, target: Character) -> void:
	## 受击扣血：先扣格挡值,格挡值减少，若为0则再减少角色血量
	var retain_amount = max(0, base_amount - target.block)
	target.block -= base_amount
	if retain_amount > 0:
		target.health -= retain_amount
