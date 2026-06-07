extends CanvasLayer

signal shop_closed

var grid: GridContainer
var shop_level: ShopLevel
var original_message_pos: Vector2

func _ready():
	original_message_pos = $MessageLabel.position
	$CloseButton.pressed.connect(_on_continue)


func setup(level: ShopLevel):
	shop_level = level
	update_gold_display()
	grid = $Panel/GridContainer
	if not grid:
		grid = GridContainer.new()
		$Panel.add_child(grid)
		grid.columns = 3
	for item in shop_level.items:
		add_item(item)


func add_item(item_data):
	var item_ui = preload("res://scenes/ui/shop_item.tscn").instantiate()
	item_ui.setup(
		item_data["item_name"],
		item_data["item_detail"],
		item_data["price"],
		item_data.get("item_icon", null)
	)
	item_ui.buy_clicked.connect(func(item_name): _on_buy(item_name, item_data["price"]))
	grid.add_child(item_ui)


func _on_buy(item_name, price):
	if GameManager.spend_gold(price):
		print("购买成功：", item_name)
		show_message("购买成功！")
		update_gold_display()
	else:
		print("金币不足，无法购买：", item_name)
		show_message("金币不足！")


func _on_continue():
	shop_closed.emit()
	queue_free()


func show_message(text: String):
	$MessageLabel.text = text
	$MessageLabel.add_theme_color_override("font_color", Color.WHITE)
	$MessageLabel.visible = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property($MessageLabel, "position:y", $MessageLabel.position.y - 80, 0.8)
	tween.tween_property($MessageLabel, "modulate:a", 0.0, 0.6)
	await tween.finished
	$MessageLabel.visible = false
	$MessageLabel.modulate.a = 1.0   # 恢复透明度
	$MessageLabel.position = original_message_pos  # 恢复位置


func update_gold_display():
	var player_state = SaveManager.load_player_state()
	if player_state:
		$GoldLabel.text = "金币：" + str(player_state.gold)
