@abstract class_name EffectResource
extends Resource

@export var effect_name: String = ""


@abstract func apply(user: Character, target: Character) -> void
	## 效果实现逻辑


@abstract func get_value()
	## 返回效果数值
