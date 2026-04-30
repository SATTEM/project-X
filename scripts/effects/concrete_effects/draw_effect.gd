class_name DrawEffect
extends EffectResource

@export var base_amount: int


func apply(user: Character, _target: Character) -> void:
	## 将效果应用到user, target上
	if not user is Player:
		printerr("Non-player is drawing!")
	if user is Player:
		user.draw_card(base_amount)
