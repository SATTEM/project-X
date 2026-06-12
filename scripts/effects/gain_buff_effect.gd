class_name GainBuffEffect
extends EffectResource
## 一次性卡牌效果：给自己赋予某种持续性 Buff

@export var buff_to_apply: BuffResource

func apply(user: Character, _target: Character) -> void:
	if buff_to_apply:
		# 复制一份 buff，防止不同角色的持续回合数互相干扰
		var buff_instance = buff_to_apply.duplicate()
		user.buff_pool.append(buff_instance)
		print(user.name, " 获得了增幅: ", buff_instance.buff_name)

func get_value() -> int:
	if buff_to_apply:
		return buff_to_apply.duration
	return 0
