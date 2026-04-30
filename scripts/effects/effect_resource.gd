# effect_resource.gd
@abstract class_name EffectResource
extends Resource


@abstract func apply(user: Character, target: Character) -> void
	## 效果实现逻辑
