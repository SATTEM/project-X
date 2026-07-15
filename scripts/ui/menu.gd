extends Control

# 抓取场景里的主菜单按钮节点	
@onready var continue_btn: Button = $MarginContainer/VBoxContainer/ContinueBtn
@onready var new_game_btn: Button = $MarginContainer/VBoxContainer/NewGameBtn
@onready var card_catalog_btn: Button = $MarginContainer/VBoxContainer/CardCatalogBtn
@onready var setting_btn: Button = $MarginContainer/VBoxContainer/SettingBtn
@onready var quit_btn: Button = $MarginContainer/VBoxContainer/QuitBtn

# 设置面板相关节点
@onready var settings_panel: Panel = $SettingsPanel
@onready var master_slider: HSlider = $SettingsPanel/MasterSlider
@onready var close_settings_btn: Button = $SettingsPanel/CloseSettingsBtn
@onready var volume_label: Label = $SettingsPanel/Label 

# 📦 新增的 3 个设置节点
@onready var fullscreen_check: CheckBox = $SettingsPanel/FullscreenCheck
@onready var fast_mode_check: CheckBox = $SettingsPanel/FastModeCheck
@onready var reset_save_btn: Button = $SettingsPanel/ResetSaveBtn

# 图鉴面板相关节点
@onready var catalog_panel: Panel = $CatalogPanel
@onready var card_grid: GridContainer = $CatalogPanel/ScrollContainer/GridContainer
@onready var close_catalog_btn: Button = $CatalogPanel/CloseCatalogBtn

@export var card_display_scene: PackedScene # 导出卡牌 UI 场景

# 这个变量用来存 Master 总线的索引
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
	
	# 🔌 连接新设置功能的功能信号
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	fast_mode_check.toggled.connect(_on_fast_mode_toggled)
	reset_save_btn.pressed.connect(_on_reset_save_pressed)
	
	# 初始化全屏和快速模式的勾选状态（同步当前系统状态）
	fullscreen_check.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	fast_mode_check.button_pressed = (Engine.time_scale > 1.0)
	
	# 真实音量是 dB，用 db_to_linear 把它转换成 0~1 的滑动条比例
	var current_db = AudioServer.get_bus_volume_db(master_bus_idx)
	master_slider.value = db_to_linear(current_db)

	var saved_state = SaveManager.load_player_state()
	var has_save = (
		saved_state != null
		and saved_state.current_hp > 0
		and CampaignManager.has_next_level(saved_state)
	)
	continue_btn.disabled = not has_save
	continue_btn.modulate.a = 1.0 if has_save else 0.5

	# === 执行动态 UI 美化与自动排版配置 ===
	_setup_settings_ui_style()

	# --- 给所有交互按钮批量绑定鼠标悬浮效果 ---
	var ui_elements = [
		continue_btn, new_game_btn, card_catalog_btn, setting_btn, quit_btn, 
		close_settings_btn, close_catalog_btn, reset_save_btn, fullscreen_check, fast_mode_check
	]
	for element in ui_elements:
		# 初始状态：复古象牙白文字 (#EAE0D5)
		element.add_theme_color_override("font_color", Color("EAE0D5"))
		element.add_theme_color_override("font_pressed_color", Color("EAE0D5"))
		# 初始状态：厚重的纯黑描边
		element.add_theme_color_override("font_outline_color", Color.BLACK)
		element.add_theme_constant_override("outline_size", 10)
		
		# 绑定鼠标悬浮和离开事件
		element.mouse_entered.connect(_on_btn_hovered.bind(element))
		element.mouse_exited.connect(_on_btn_unhovered.bind(element))

# --- 🛠️ 纯代码控制的 UI 美化与自动动态排版 ---
func _setup_settings_ui_style() -> void:
	# 1. 让设置面板强行铺满全屏，做成暗色背景遮罩
	settings_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mask_style = StyleBoxFlat.new()
	mask_style.bg_color = Color(0, 0, 0, 0.65) # 纯黑底色 + 65% 透明度
	settings_panel.add_theme_stylebox_override("panel", mask_style)
	
	# 2. 美化“主音量”文本标签
	if volume_label:
		volume_label.add_theme_color_override("font_color", Color("EAE0D5"))
		volume_label.add_theme_color_override("font_outline_color", Color.BLACK)
		volume_label.add_theme_constant_override("outline_size", 10)
	
	# 3. 像素级重雕滑动条 (HSlider) 轨道
	var slider_bg = StyleBoxFlat.new()
	slider_bg.bg_color = Color("222222")
	slider_bg.expand_margin_top = 5
	slider_bg.expand_margin_bottom = 5
	slider_bg.corner_radius_top_left = 4
	slider_bg.corner_radius_bottom_left = 4
	slider_bg.corner_radius_top_right = 4
	slider_bg.corner_radius_bottom_right = 4
	master_slider.add_theme_stylebox_override("slider", slider_bg)
	
	var slider_fill = StyleBoxFlat.new()
	slider_fill.bg_color = Color("FFD700")
	slider_fill.expand_margin_top = 5
	slider_fill.expand_margin_bottom = 5
	slider_fill.corner_radius_top_left = 4
	slider_fill.corner_radius_bottom_left = 4
	master_slider.add_theme_stylebox_override("grabber_area", slider_fill)
	master_slider.add_theme_stylebox_override("grabber_area_highlight", slider_fill)

	# 📐 4. 核心：三大音量独立持久化存档 + 解决返回主菜单设置重置（第十三版）
	var volume_label = settings_panel.get_node("Label")
	var master_slider = settings_panel.get_node("MasterSlider")
	
	# 🎯 1. 统一大字号
	var target_font_size = 52 
	volume_label.add_theme_font_size_override("font_size", target_font_size)
	
	# 🗑️ 2. 【功能移除】隐藏“清空存档”按钮
	var reset_save_btn = settings_panel.get_node_or_null("ResetSaveBtn")
	if reset_save_btn:
		reset_save_btn.hide()

	# 🌿 3. 【三音量动态生成】
	var bgm_label = settings_panel.get_node_or_null("BgmLabel")
	var bgm_slider = settings_panel.get_node_or_null("BgmSlider")
	if not bgm_label:
		bgm_label = volume_label.duplicate()
		bgm_label.name = "BgmLabel"
		bgm_label.text = "背景音量"
		settings_panel.add_child(bgm_label)
	if not bgm_slider:
		bgm_slider = master_slider.duplicate()
		bgm_slider.name = "BgmSlider"
		settings_panel.add_child(bgm_slider)

	var sfx_label = settings_panel.get_node_or_null("SfxLabel")
	var sfx_slider = settings_panel.get_node_or_null("SfxSlider")
	if not sfx_label:
		sfx_label = volume_label.duplicate()
		sfx_label.name = "SfxLabel"
		settings_panel.add_child(sfx_label)
	if not sfx_slider:
		sfx_slider = master_slider.duplicate()
		sfx_slider.name = "SfxSlider"
		settings_panel.add_child(sfx_slider)
	
	sfx_label.name = "SfxLabel"
	sfx_label.text = "音效音量"

	# 📏 4. 统一滑动条物理长度
	var slider_width = 380
	master_slider.custom_minimum_size = Vector2(slider_width, 30)
	bgm_slider.custom_minimum_size = Vector2(slider_width, 30)
	sfx_slider.custom_minimum_size = Vector2(slider_width, 30)

	# 📍 5. 【坐标对齐】
	if not settings_panel.has_meta("true_original_y"):
		settings_panel.set_meta("true_original_y", volume_label.position.y)
	
	var base_y = settings_panel.get_meta("true_original_y") + 20
	volume_label.position.y = base_y

	var base_x = volume_label.position.x
	var slider_x = base_x + 265                    
	var slider_y_offset = -16                       
	var row_spacing = 100                          

	master_slider.position = Vector2(slider_x, base_y + slider_y_offset)
	bgm_label.position = Vector2(base_x, base_y + row_spacing)
	bgm_slider.position = Vector2(slider_x, bgm_label.position.y + slider_y_offset)
	sfx_label.position = Vector2(base_x, base_y + row_spacing * 2)
	sfx_slider.position = Vector2(slider_x, sfx_label.position.y + slider_y_offset)

	# ==========================================
	# ⚡️ 核心修复区：独立持久化存档与状态同步
	# ==========================================
	
	var clear_connections = func(sig: Signal):
		for conn in sig.get_connections():
			sig.disconnect(conn.callable)

	clear_connections.call(master_slider.value_changed)
	clear_connections.call(bgm_slider.value_changed)
	clear_connections.call(sfx_slider.value_changed)

	# ------------------------------------------
	# 🔄 状态同步：读取独立存档，防止返回菜单时重置
	# ------------------------------------------
	var custom_cfg_path = "user://audio_settings_ext.cfg"
	var custom_cfg = ConfigFile.new()
	
	# 尝试读取我们自己的高级音量存档
	if custom_cfg.load(custom_cfg_path) == OK:
		if custom_cfg.has_section_key("Audio", "master"):
			master_slider.set_value_no_signal(custom_cfg.get_value("Audio", "master"))
		if custom_cfg.has_section_key("Audio", "bgm"):
			bgm_slider.set_value_no_signal(custom_cfg.get_value("Audio", "bgm"))
		if custom_cfg.has_section_key("Audio", "sfx"):
			sfx_slider.set_value_no_signal(custom_cfg.get_value("Audio", "sfx"))
	elif Engine.has_meta("ui_master"):
		# 兜底：如果文件没能读取，尝试从引擎跨场景内存中读取
		master_slider.set_value_no_signal(Engine.get_meta("ui_master"))
		bgm_slider.set_value_no_signal(Engine.get_meta("ui_bgm"))
		sfx_slider.set_value_no_signal(Engine.get_meta("ui_sfx"))
	else:
		# 首次初始化：让克隆出的滑块继承当前主音量的值
		bgm_slider.set_value_no_signal(master_slider.value)
		sfx_slider.set_value_no_signal(master_slider.value)

	# ------------------------------------------
	# 🎛️ 混音计算与保存逻辑
	# ------------------------------------------
	var master_bus_idx = AudioServer.get_bus_index("Master")
	
	var bgm_bus_idx = -1
	for b_name in ["BGM", "Music", "bgm", "music", "Bgm"]:
		var idx = AudioServer.get_bus_index(b_name)
		if idx != -1: bgm_bus_idx = idx; break

	var sfx_bus_idx = -1
	for b_name in ["SFX", "Sfx", "sfx", "Sound", "Sounds", "sound", "SoundEffects"]:
		var idx = AudioServer.get_bus_index(b_name)
		if idx != -1: sfx_bus_idx = idx; break

	var check_routes_to_master = func(bus_idx: int) -> bool:
		if bus_idx == -1 or master_bus_idx == -1: return false
		return AudioServer.get_bus_send(bus_idx) == "Master"

	var apply_audio_volumes = func():
		var master_val = master_slider.value 
		var bgm_val = bgm_slider.value       
		var sfx_val = sfx_slider.value       
		
		# 乘法逻辑：总音量 * 对应音量
		var final_bgm = master_val * bgm_val
		var final_sfx = master_val * sfx_val
		
		if master_bus_idx != -1:
			AudioServer.set_bus_volume_db(master_bus_idx, linear_to_db(master_val))
			AudioServer.set_bus_mute(master_bus_idx, master_val <= 0.0001)

		if bgm_bus_idx != -1:
			var apply_bgm_val = bgm_val if check_routes_to_master.call(bgm_bus_idx) else final_bgm
			AudioServer.set_bus_volume_db(bgm_bus_idx, linear_to_db(apply_bgm_val))
			AudioServer.set_bus_mute(bgm_bus_idx, apply_bgm_val <= 0.0001)

		if sfx_bus_idx != -1:
			var apply_sfx_val = sfx_val if check_routes_to_master.call(sfx_bus_idx) else final_sfx
			AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(apply_sfx_val))
			AudioServer.set_bus_mute(sfx_bus_idx, apply_sfx_val <= 0.0001)

	# 实时滑动仅应用，不存盘（告别卡顿）
	master_slider.value_changed.connect(func(_val): apply_audio_volumes.call())
	bgm_slider.value_changed.connect(func(_val): apply_audio_volumes.call())
	sfx_slider.value_changed.connect(func(_val): apply_audio_volumes.call())

	# 松开鼠标时才进行落盘保存
	var on_drag_ended = func(_value_changed: bool):
		# 1. 保存到我们的专属配置文件（重启生效）
		custom_cfg.set_value("Audio", "master", master_slider.value)
		custom_cfg.set_value("Audio", "bgm", bgm_slider.value)
		custom_cfg.set_value("Audio", "sfx", sfx_slider.value)
		custom_cfg.save(custom_cfg_path)
		
		# 2. 存入引擎内存，双保险防止丢档
		Engine.set_meta("ui_master", master_slider.value)
		Engine.set_meta("ui_bgm", bgm_slider.value)
		Engine.set_meta("ui_sfx", sfx_slider.value)

		# 3. 兼容调用原项目的保存代码
		for save_func in ["save_settings", "save_config", "_save_config", "save_game"]:
			if has_method(save_func):
				call(save_func)
				break

	if master_slider.has_signal("drag_ended"):
		clear_connections.call(master_slider.drag_ended)
		clear_connections.call(bgm_slider.drag_ended)
		clear_connections.call(sfx_slider.drag_ended)
		master_slider.drag_ended.connect(on_drag_ended)
		bgm_slider.drag_ended.connect(on_drag_ended)
		sfx_slider.drag_ended.connect(on_drag_ended)

	# 初始化执行一次混音
	apply_audio_volumes.call()

	# 📐 6. 复选框自适应排版
	var start_y = sfx_label.position.y + 100       
	var checkbox_v_spacing = 110                   
	var checkbox_x = base_x

	var optimize_checkbox = func(cb: CheckBox):
		cb.add_theme_font_size_override("font_size", target_font_size)
		cb.layout_direction = Control.LAYOUT_DIRECTION_RTL
		cb.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
		cb.add_theme_constant_override("h_separation", 40)
		
		var target_icon_size = target_font_size - 10
		for icon_state in ["checked", "unchecked", "checked_disabled", "unchecked_disabled"]:
			var default_tex = cb.get_theme_icon(icon_state, "CheckBox")
			if default_tex:
				var img = default_tex.get_image()
				img.resize(target_icon_size, target_icon_size, Image.INTERPOLATE_LANCZOS)
				cb.add_theme_icon_override(icon_state, ImageTexture.create_from_image(img))

	# 1. 全屏模式复选框
	var fullscreen_check = settings_panel.get_node("FullscreenCheck")
	optimize_checkbox.call(fullscreen_check)
	fullscreen_check.custom_minimum_size = Vector2(460, 80)
	fullscreen_check.position = Vector2(checkbox_x, start_y)
	
	# 💡 【全屏同步】：直接读取系统底层窗口状态，防止返回菜单时复选框显示错误
	var is_fullscreen = (get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN or get_window().mode == Window.MODE_FULLSCREEN)
	fullscreen_check.set_pressed_no_signal(is_fullscreen)

	# 2. 快速模式（加速模式）复选框
	var fast_mode_check = settings_panel.get_node("FastModeCheck")
	optimize_checkbox.call(fast_mode_check)
	fast_mode_check.custom_minimum_size = Vector2(460, 80)
	fast_mode_check.position = Vector2(checkbox_x, start_y + checkbox_v_spacing)



# --- 鼠标悬浮动画逻辑 ---

func _on_btn_hovered(node: Control) -> void:
	if node is Button and node.disabled:
		return
	
	# 修改文字颜色为金黄色 (#FFD700) 
	node.add_theme_color_override("font_hover_color", Color("FFD700"))
	node.add_theme_color_override("font_color", Color("FFD700"))
	
	node.pivot_offset = node.size / 2.0 
	node.scale = Vector2(1.1, 1.1)


func _on_btn_unhovered(node: Control) -> void:
	if node is Button and node.disabled:
		return
		
	# 鼠标离开时，恢复原本的复古象牙白 (#EAE0D5)
	node.add_theme_color_override("font_color", Color("EAE0D5"))
	
	node.scale = Vector2(1.0, 1.0)


# --- 设置面板新功能实现 ---

# 📺 功能 1：窗口与全屏切换切换
func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# ⚡ 功能 2：快速模式（全局 1.5 倍速）
func _on_fast_mode_toggled(toggled_on: bool) -> void:
	if toggled_on:
		Engine.time_scale = 1.5
		print("快速模式已开启：1.5倍速")
	else:
		Engine.time_scale = 1.0
		print("快速模式已关闭")

# 💾 功能 3：重置存档
func _on_reset_save_pressed() -> void:
	print("正在清空游戏存档...")
	SaveManager.delete_player_state()
	
	# 让主菜单的“继续游戏”按钮立刻灰掉
	continue_btn.disabled = true
	continue_btn.modulate.a = 0.5
	
	# 关闭设置面板返回主菜单
	settings_panel.hide()


# --- 原有按钮功能实现 ---

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


# --- 设置显示隐藏与滑动条 ---

func _on_setting_pressed() -> void:
	settings_panel.show()


func _on_close_settings_pressed() -> void:
	settings_panel.hide()


func _on_master_slider_changed(value: float) -> void:
	var db_volume = linear_to_db(value)
	AudioServer.set_bus_volume_db(master_bus_idx, db_volume)
	AudioServer.set_bus_mute(master_bus_idx, value < 0.01)


# --- 图鉴功能实现 ---

func _on_card_catalog_pressed() -> void:
	catalog_panel.show()
	for child in card_grid.get_children():
		child.queue_free()
		
	var unlock_state = SaveManager.load_unlock_state()
	var unlocked_ids: Array[String] = []
	
	if unlock_state:
		unlocked_ids = unlock_state.unlocked_ids
	else:
		print("没有找到解锁存档，展示默认的基础4张牌")
		unlocked_ids = ["base_attack", "base_defend", "base_draw", "base_summon"]
		
	for card_id in unlocked_ids:
		var card_ui = card_display_scene.instantiate()
		var card_resource = CardLibrary.create_card(card_id)
			
		if card_resource:
			card_ui.set_card(card_resource)
			card_grid.add_child(card_ui)
		else:
			print("图鉴加载警告：找不到 ID 为 ", card_id, " 的卡牌资源！")


func _on_close_catalog_pressed() -> void:
	catalog_panel.hide()
