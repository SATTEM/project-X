extends Panel

signal buy_clicked(item_resource: ShopItemResource)

var item_resource: ShopItemResource

func setup(item: ShopItemResource):
	item_resource = item
	
	var name_label = get_node("VBoxContainer/Name")
	var detail_label = get_node("VBoxContainer/Detail")
	var buy_button = get_node("VBoxContainer/BuyButton")
	var icon_rect = get_node("VBoxContainer/Icon")
	
	name_label.text = item.item_name
	detail_label.text = item.item_detail
	buy_button.text = str(item.price) + "金币"
	if item.icon:
		icon_rect.texture = item.icon
	
	buy_button.pressed.connect(_on_buy)


func _on_buy():
	buy_clicked.emit(item_resource)
