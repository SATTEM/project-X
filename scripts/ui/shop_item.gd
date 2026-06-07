extends Panel

signal buy_clicked(item_id)

@export var item_name: String = ""
@export var item_detail: String = ""
@export var price: int = 0
@export var item_icon: Texture2D

func setup(name, detail, price_val, icon_tex):
	item_name = name
	item_detail = detail
	price = price_val
	item_icon = icon_tex
	$VBoxContainer/Name.text = item_name
	$VBoxContainer/Detail.text = item_detail
	$VBoxContainer/BuyButton.text = str(price) + "金币"
	$VBoxContainer/Icon.texture = item_icon

func _ready():
	$VBoxContainer/BuyButton.pressed.connect(func(): buy_clicked.emit(item_name))
	
