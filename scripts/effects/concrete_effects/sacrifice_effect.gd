class_name SacrificeEffect
extends EffectResource
## 卡牌效果：清理/献祭目标随从


func apply(_user: Character, target: Character) -> void:
	# 检查目标是不是一个活着的随从
	if target is Monster and target.has_method("sacrifice_minion"):
		target.sacrifice_minion()


func get_value() -> int:
	return 0
