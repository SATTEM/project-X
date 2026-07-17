class_name HealLowestFriendlyEffect
extends EffectResource

@export var base_amount: int = 0


func apply(user: Character, _target: Character) -> void:
	var lowest_health_character: Character = null
	var lowest_health_ratio := INF

	for character in BattleManager.get_all_character():
		if character.is_dead or character.is_ally != user.is_ally:
			continue
		var health_ratio := float(character.health) / maxf(float(character.health_max), 1.0)
		if health_ratio < lowest_health_ratio:
			lowest_health_ratio = health_ratio
			lowest_health_character = character

	if lowest_health_character:
		lowest_health_character.heal(base_amount)


func get_value():
	return base_amount
