class_name Card
extends Node2D
## 卡牌脚本

@export var card_resource: CardResource
var effects: Array[EffectResource] = []
var bound_monster_id: String = ""
var card_name: String:
	get:
		return card_resource.card_name
var cost: int:
	get:
		return card_resource.cost
var target_type: GlobalEnums.TargetType:
	get:
		return card_resource.target_type
var card_description: String:
	get:
		return card_resource.description

func play_card_on_target(user: Character, target: Character) -> void:
	## 结算卡牌效果
	print(user.name + " played card: [" + card_name+"] at: [" + target.name + "]")
	for effect in effects:
		effect.apply(user, target)
	return


func set_summon_binding(monster_id: String) -> void:
	bound_monster_id = monster_id
	for effect in effects:
		if effect is SummonEffect:
			effect.monster_id = monster_id


func create_buffed_copy() -> Card:
	## 生成用于结算的临时克隆卡，防止污染原卡牌
	var copy = self.duplicate() # 复制节点
	
	# 深拷贝核心资源，确保 Buff 修改费用/伤害时不会影响原牌库
	if card_resource:
		copy.card_resource = card_resource.duplicate(true)
		
	var new_effects: Array[EffectResource] = []
	for e in effects:
		new_effects.append(e.duplicate(true))
	copy.effects = new_effects
	copy.set_summon_binding(bound_monster_id)
	
	return copy
