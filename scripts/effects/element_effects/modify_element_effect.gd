class_name ModifyElementEffect
extends EffectResource
## 元素卡牌效果：增加或减少目标的特定元素点

@export var target_element: GlobalEnums.Element = GlobalEnums.Element.FIRE
@export var change_amount: int = -2 # 正数为充能，负数为削减（吸蓝）
@export var use_highest_energy_element: bool = false


func apply(_user: Character, target: Character) -> void:
	if target is Monster and target.has_method("modify_element_points"):
		var element := target_element
		if use_highest_energy_element:
			element = target.get_highest_energy_element()
		if element != GlobalEnums.Element.UNKNOWN:
			target.modify_element_points(element, change_amount)


func get_value() -> int:
	return abs(change_amount)
