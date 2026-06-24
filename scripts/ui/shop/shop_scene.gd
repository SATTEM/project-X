extends CanvasLayer

signal shop_closed

var grid: GridContainer
var shop_level: ShopLevel
var original_message_pos: Vector2
var player: Player

func _ready():
	original_message_pos = $MessageLabel.position
	$CloseButton.pressed.connect(_on_continue)


func setup(level: ShopLevel, current_player: Player):
	shop_level = level
	player = current_player
	update_gold_display()
	grid = $Panel/GridContainer
	if not grid:
		grid = GridContainer.new()
		$Panel.add_child(grid)
		grid.columns = 3
	for item in shop_level.items:
		add_item(item)


func add_item(item: ShopItemResource):
	var item_ui = preload("res://scenes/ui/shop_item.tscn").instantiate()
	grid.add_child(item_ui)
	item_ui.setup(item)
	item_ui.buy_clicked.connect(_on_buy)


func _on_buy(item: ShopItemResource):
	var state = SaveManager.load_player_state()
	if not state or state.gold < item.price:
		show_message("金币不足！")
		return
	state.gold -= item.price
	SaveManager.save_player_state(state)
	update_gold_display()
	
	# 应用效果
	for effect in item.effects:
		effect.apply(player, player)
	
	for buff in item.buffs:
		player.add_buff(buff)
	
	show_message("购买成功：" + item.item_name)


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
