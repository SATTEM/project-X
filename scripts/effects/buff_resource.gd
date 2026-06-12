class_name BuffResource
extends Resource
## 增幅/Buff的基类

@export var buff_name: String = "未知增幅"
@export var duration: int = 1 # 持续回合数

func apply_to_card(card: Card) -> Card:
	## 核心拦截方法：子类重写此方法来修改卡牌
	## 例如：力量 Buff 可以遍历 card.effects 找到伤害效果并加大数值
	return card

func on_turn_end() -> void:
	## 回合结束时调用
	duration -= 1
