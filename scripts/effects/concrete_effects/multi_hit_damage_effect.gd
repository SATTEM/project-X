class_name MultiHitDamageEffect
extends EffectResource

@export var damage_per_hit: int = 0
@export var hit_count: int = 1


func apply(_user: Character, target: Character) -> void:
	for _hit_index in range(hit_count):
		if target.is_dead:
			break
		target.take_damage(damage_per_hit)


func get_value():
	return damage_per_hit * hit_count
