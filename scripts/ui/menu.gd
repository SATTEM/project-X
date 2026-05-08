extends Control

# 抓取场景里的按钮节点	
@onready var continue_btn: Button = $MarginContainer/VBoxContainer/ContinueBtn
@onready var new_game_btn: Button = $MarginContainer/VBoxContainer/NewGameBtn
@onready var card_catalog_btn: Button = $MarginContainer/VBoxContainer/CardCatalogBtn
@onready var setting_btn: Button = $MarginContainer/VBoxContainer/SettingBtn
@onready var quit_btn: Button = $MarginContainer/VBoxContainer/QuitBtn


func _ready() -> void:
	BattleManager.hide()
	
	# 当按钮被按下时，连接到对应的功能函数
	new_game_btn.pressed.connect(_on_new_game_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	continue_btn.pressed.connect(_on_continue_pressed) 
	
	if not BattleManager.is_active or BattleManager.player.health <= 0:
		continue_btn.disabled = true
		continue_btn.modulate.a = 0.5 
	else:
		continue_btn.disabled = false
		continue_btn.modulate.a = 1.0

	# --- 给所有按钮批量绑定鼠标悬浮效果 ---
	var buttons = [continue_btn, new_game_btn, card_catalog_btn, setting_btn, quit_btn]
	for btn in buttons:
		# bind(btn) 的作用是把当前按钮作为参数传给函数，这样一个函数就能管所有按钮
		btn.mouse_entered.connect(_on_btn_hovered.bind(btn))
		btn.mouse_exited.connect(_on_btn_unhovered.bind(btn))


# --- 鼠标悬浮动画逻辑 ---

func _on_btn_hovered(btn: Button) -> void:
	# 如果按钮是灰掉的（比如禁用的 Continue），就不触发效果
	if btn.disabled:
		return
	
	# 修改颜色为金黄色 
	btn.add_theme_color_override("font_hover_color", Color.GOLD)
	btn.add_theme_color_override("font_color", Color.GOLD)
	
	# 如果不写这句，按钮会默认从左上角开始放大，看起来会往右下角歪
	btn.pivot_offset = btn.size / 2.0 
	# 使用 Scale 进行视觉放大 (1.2 表示放大到 120%)
	btn.scale = Vector2(1.2, 1.2)


func _on_btn_unhovered(btn: Button) -> void:
	if btn.disabled:
		return
		
	# 鼠标离开时，移除覆盖的属性，恢复原状
	btn.remove_theme_color_override("font_hover_color")
	btn.remove_theme_color_override("font_color")
	btn.remove_theme_font_size_override("font_size")
	# 恢复原本的缩放比例 (100%)
	btn.scale = Vector2(1.0, 1.0)
	
# --- 按钮功能实现 ---

func _on_new_game_pressed() -> void:
	print("开始新游戏！正在跳转场景...")
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_quit_pressed() -> void:
	print("退出游戏")
	get_tree().quit()

func _on_continue_pressed() -> void:
	BattleManager.show()
	get_tree().change_scene_to_file("res://scenes/game.tscn")
