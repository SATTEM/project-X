@abstract class_name MonsterPlayStrategy
extends Resource


## 从手牌中按策略选出一张牌，返回 null 表示跳过
@abstract func select_card(hand: Array[ElementCard], monster: Monster) -> ElementCard

## 为指定卡牌选择目标
@abstract func choose_target(card: Card, monster: Monster, all_characters: Array[Character]) -> Character
