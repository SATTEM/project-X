class_name CardResource
extends Resource
## 卡牌资源脚本，作为资源和工厂

@export var card_name: String = "攻击"
@export var cost: int = 0
@export var effects: Array[String]
@export var texture: Texture2D

func transeffects() -> Array[Callable]:
	var callables: Array[Callable] = []
	for effect in effects:
		var part = effect.split(":")
		if part.size() == 2:
			var type = part[0]
			var value = int(part[1])
			var curr_value = value
			match type:
				"damage":
					callables.append(func(user: Character, target: Character):
						target.take_damage(curr_value)
					)
				"block":
					callables.append(func(user: Character, target: Character):
						user.add_block(curr_value)
					)
				"draw":
					callables.append(func(user: Character, target: Character):
						if user is Player:
							user.draw_card(curr_value)
					)
	return callables
