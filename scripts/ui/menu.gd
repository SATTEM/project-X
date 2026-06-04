extends Control

# 抓取场景里的按钮节点	
@onready var continue_btn: Button = $MarginContainer/VBoxContainer/ContinueBtn
@onready var new_game_btn: Button = $MarginContainer/VBoxContainer/NewGameBtn
@onready var card_catalog_btn: Button = $MarginContainer/VBoxContainer/CardCatalogBtn
@onready var setting_btn: Button = $MarginContainer/VBoxContainer/SettingBtn
@onready var quit_btn: Button = $MarginContainer/VBoxContainer/QuitBtn
@onready var settings_panel: Panel = $SettingsPanel
@onready var master_slider: HSlider = $SettingsPanel/MasterSlider
@onready var close_settings_btn: Button = $SettingsPanel/CloseSettingsBtn
@onready var catalog_panel: Panel = $CatalogPanel
@onready var card_grid: GridContainer = $CatalogPanel/ScrollContainer/GridContainer
@onready var close_catalog_btn: Button = $CatalogPanel/CloseCatalogBtn

@export var card_display_scene: PackedScene# 导出卡牌 UI 场景

# 这个变量用来存 Master 总线的索引（Godot 底层用来找声音通道的编号）
var master_bus_idx: int

func _ready() -> void:
	BattleManager.hide()
	
	master_bus_idx = AudioServer.get_bus_index("Master")
	
	# 当按钮被按下时，连接到对应的功能函数
	new_game_btn.pressed.connect(_on_new_game_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	continue_btn.pressed.connect(_on_continue_pressed) 
	setting_btn.pressed.connect(_on_setting_pressed)
	close_settings_btn.pressed.connect(_on_close_settings_pressed)
	master_slider.value_changed.connect(_on_master_slider_changed)
	card_catalog_btn.pressed.connect(_on_card_catalog_pressed)
	close_catalog_btn.pressed.connect(_on_close_catalog_pressed)
	
	# 真实音量是 dB，用 db_to_linear 把它转换成 0~1 的滑动条比例
	var current_db = AudioServer.get_bus_volume_db(master_bus_idx)
	master_slider.value = db_to_linear(current_db)

	var saved_state = SaveManager.load_player_state()
	var has_save = (
		saved_state != null
		and saved_state.current_hp > 0
		and CampaignManager.has_next_battle(saved_state)
	)
	continue_btn.disabled = not has_save
	continue_btn.modulate.a = 1.0 if has_save else 0.5

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
	print("开始新游戏！正在清理旧存档...")
	
	# 只要删了旧档，game.tscn 里的 GameManager 发现没档，就会自动执行 start_new_run() 给你发初始牌。
	SaveManager.delete_player_state()
	
	# 恢复战场UI显示并切换场景
	BattleManager.show()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_quit_pressed() -> void:
	print("退出游戏")
	get_tree().quit()


func _on_continue_pressed() -> void:
	print("继续游戏！正在恢复战场...")
	
	# 只要硬盘里有档，直接跳过去，GameManager 会自己接管一切。
	BattleManager.show()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


# --- 按钮与滑动条功能实现 ---

func _on_setting_pressed() -> void:
	## 点击设置按钮，显示设置面板
	settings_panel.show()


func _on_close_settings_pressed() -> void:
	## 点击关闭按钮，隐藏设置面板
	settings_panel.hide()


func _on_master_slider_changed(value: float) -> void:
	## 当滑动条被拖动时触发
	# value 就是滑动条当前的值 (0.0 到 1.0)
	# 用 linear_to_db 把 0~1 的线性值，转换成 Godot 需要的对数分贝值
	var db_volume = linear_to_db(value)
	AudioServer.set_bus_volume_db(master_bus_idx, db_volume)
	
	# 如果音量滑到最左边（比如小于 0.01），可以考虑直接静音，防止还有底噪
	AudioServer.set_bus_mute(master_bus_idx, value < 0.01)


# --- 图鉴功能实现 ---

func _on_card_catalog_pressed() -> void:
	# 显示图鉴面板
	catalog_panel.show()
	
	# 清空旧的卡牌（防止每次打开重复生成）
	for child in card_grid.get_children():
		child.queue_free()
		
	# 读取全局解锁进度
	var unlock_state = SaveManager.load_unlock_state()
	var unlocked_ids: Array[String] = []
	
	if unlock_state:
		unlocked_ids = unlock_state.unlocked_ids
	else:
		print("没有找到解锁存档，展示默认的基础4张牌")
		unlocked_ids = ["base_attack", "base_defend", "base_draw", "base_summon"]
		
	# 生成并展示卡牌
	for card_id in unlocked_ids:
		
		var card_ui = card_display_scene.instantiate() # 实例化UI框
		var card_resource = CardLibrary.create_card(card_id)
			
		if card_resource:
			card_ui.set_card(card_resource) # 把真实数据塞进 UI 里
			card_grid.add_child(card_ui)    # 把卡牌 UI 放进网格里显示
		else:
			print("图鉴加载警告：找不到 ID 为 ", card_id, " 的卡牌资源！")


func _on_close_catalog_pressed() -> void:
	# 隐藏图鉴面板
	catalog_panel.hide()
