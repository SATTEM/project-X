class_name GlobalEnums
extends Node
## 全局枚举

## 元素类型
enum Element {
	UNKNOWN,
	FIRE,
	WATER,
	SOIL,
}
## 元素类型对应的颜色
static var ElementColor = {
	Element.UNKNOWN: Color.BLACK,
	Element.FIRE: Color.RED,
	Element.WATER: Color.AQUAMARINE,
	Element.SOIL: Color.BROWN,
}
## 元素类型对应的图标
static var ElementIcon = {
	GlobalEnums.Element.WATER: preload("res://assets/art/elements/water.png"),
	GlobalEnums.Element.FIRE: preload("res://assets/art/elements/fire.png"),
	GlobalEnums.Element.SOIL: preload("res://assets/art/elements/soil.png"),
}
## 站位排列
enum PositionRow {
	PLAYER,
	FRONT,
	ENEMY,
}
