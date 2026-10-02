extends Control

const SETTINGS_OVERLAY_SCENE := preload("res://scenes/ui/battle_settings_overlay.tscn")

@onready var continue_btn: Button = $MarginContainer/VBoxContainer/ContinueBtn
@onready var new_game_btn: Button = $MarginContainer/VBoxContainer/NewGameBtn
@onready var card_catalog_btn: Button = $MarginContainer/VBoxContainer/CardCatalogBtn
@onready var setting_btn: Button = $MarginContainer/VBoxContainer/SettingBtn
@onready var quit_btn: Button = $MarginContainer/VBoxContainer/QuitBtn

@onready var catalog_panel: Panel = $CatalogPanel
@onready var card_grid: GridContainer = $CatalogPanel/Window/Margin/VBox/ScrollContainer/GridContainer
@onready var catalog_count_label: Label = $CatalogPanel/Window/Margin/VBox/Header/Count
@onready var close_catalog_btn: Button = $CatalogPanel/Window/Margin/VBox/Header/CloseCatalogBtn
@onready var dismiss_catalog_btn: Button = $CatalogPanel/DismissButton

@export var card_display_scene: PackedScene

var _settings_overlay: BattleSettingsOverlay


func _ready() -> void:
	BattleManager.hide()
	new_game_btn.pressed.connect(_on_new_game_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	setting_btn.pressed.connect(_on_setting_pressed)
	card_catalog_btn.pressed.connect(_on_card_catalog_pressed)
	close_catalog_btn.pressed.connect(_on_close_catalog_pressed)
	dismiss_catalog_btn.pressed.connect(_on_close_catalog_pressed)
	get_viewport().size_changed.connect(_layout_catalog)
	_layout_catalog()

	var saved_state = SaveManager.load_player_state()
	var has_save = (
		saved_state != null
		and saved_state.current_hp > 0
		and CampaignManager.has_next_level(saved_state)
	)
	continue_btn.disabled = not has_save
	continue_btn.modulate.a = 1.0 if has_save else 0.5

	for element in [
		continue_btn,
		new_game_btn,
		card_catalog_btn,
		setting_btn,
		quit_btn,
		close_catalog_btn,
	]:
		element.add_theme_color_override("font_color", Color("EAE0D5"))
		element.add_theme_color_override("font_pressed_color", Color("EAE0D5"))
		element.add_theme_color_override("font_outline_color", Color.BLACK)
		element.add_theme_constant_override("outline_size", 10)
		element.mouse_entered.connect(_on_btn_hovered.bind(element))
		element.mouse_exited.connect(_on_btn_unhovered.bind(element))


func _on_btn_hovered(node: Control) -> void:
	if node is Button and node.disabled:
		return
	node.add_theme_color_override("font_hover_color", Color("FFD700"))
	node.add_theme_color_override("font_color", Color("FFD700"))
	node.pivot_offset = node.size * 0.5
	node.scale = Vector2(1.1, 1.1)


func _on_btn_unhovered(node: Control) -> void:
	if node is Button and node.disabled:
		return
	node.add_theme_color_override("font_color", Color("EAE0D5"))
	node.scale = Vector2.ONE


func _on_new_game_pressed() -> void:
	print("开始新游戏！正在清理旧存档...")
	SaveManager.delete_player_state()
	BattleManager.show()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_quit_pressed() -> void:
	print("退出游戏")
	get_tree().quit()


func _on_continue_pressed() -> void:
	print("继续游戏！正在恢复战场...")
	BattleManager.show()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_setting_pressed() -> void:
	if _settings_overlay and is_instance_valid(_settings_overlay):
		return
	_settings_overlay = SETTINGS_OVERLAY_SCENE.instantiate() as BattleSettingsOverlay
	_settings_overlay.title_text = "游戏设置"
	add_child(_settings_overlay)
	_settings_overlay.closed.connect(func(): _settings_overlay = null)


func _on_card_catalog_pressed() -> void:
	catalog_panel.show()
	for child in card_grid.get_children():
		child.queue_free()

	var all_card_ids := CardLibrary.get_all_card_ids()
	all_card_ids.sort()
	catalog_count_label.text = "共 %d 张" % all_card_ids.size()

	for card_id in all_card_ids:
		var card_ui := card_display_scene.instantiate() as CardDisplay
		var card := CardLibrary.create_card(card_id)
		if card:
			card_ui.add_child(card)
			card_ui.set_card(card)
			card_ui.set_click_enabled(false)
			card_grid.add_child(card_ui)
		else:
			card_ui.queue_free()
			print("图鉴加载警告：找不到 ID 为 ", card_id, " 的卡牌资源！")


func _on_close_catalog_pressed() -> void:
	catalog_panel.hide()


func _layout_catalog() -> void:
	catalog_panel.position = Vector2.ZERO
	catalog_panel.size = get_viewport_rect().size
