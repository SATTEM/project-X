class_name DisableElementEffect
extends EffectResource
## 元素卡牌效果：直接封印/禁用目标的某个元素属性（使其无法回复）

@export var target_element: GlobalEnums.Element = GlobalEnums.Element.FIRE

func apply(_user: Character, target: Character) -> void:
	if target is Monster and target.has_method("disable_element"):
		target.disable_element(target_element)

func get_value() -> int:
	return 0
