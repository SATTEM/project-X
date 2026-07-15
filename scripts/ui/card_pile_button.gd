class_name CardPileButton
extends Button

@export_enum("draw", "discard") var pile_kind: String = "draw"

@onready var _icon: CardPileIcon = $Icon
@onready var _name_label: Label = $NameLabel
@onready var _count_label: Label = $CountLabel


func _ready() -> void:
	_icon.pile_kind = pile_kind
	_name_label.text = "抽牌堆" if pile_kind == "draw" else "弃牌堆"
	tooltip_text = "查看%s" % _name_label.text
	set_card_count(0)


func set_card_count(count: int) -> void:
	_count_label.text = str(maxi(count, 0))
