class_name GainBuffEffect
extends EffectResource
## 一次性卡牌效果：给自己赋予某种持续性 Buff

@export var buff_to_apply: BuffResource


func apply(user: Character, _target: Character) -> void:
	if buff_to_apply:
		# 统一通过角色接口添加，确保每次得到独立的 Buff 实例。
		user.add_buff(buff_to_apply)


func get_value() -> int:
	if buff_to_apply:
		return buff_to_apply.duration
	return 0
