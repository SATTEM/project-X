extends Resource
class_name CardResource

@export var card_name: String = "攻击"
@export var cost: int = 0
@export var effects: Array[String]
@export var texture: Texture2D

func transeffects() -> Array[Callable]:
	var callables: Array[Callable] = []
	for str in effects:
		var part = str.split(":")
		if part.size() == 2:
			var type = part[0]
			var value = int(part[1])
			match type:
				"damage":
					callables.append(func(target: Character):
						target.take_damage(value)
					)
	return callables
