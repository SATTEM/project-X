class_name BattleSettingsOverlay
extends Control

signal closed

const CONFIG_PATH := "user://audio_settings_ext.cfg"

@export var title_text := "战斗设置"

@onready var _dimmer: ColorRect = $Dimmer
@onready var _dismiss_button: Button = $DismissButton
@onready var _panel: PanelContainer = $Panel
@onready var _close_button: Button = $Panel/Margin/VBox/Header/CloseButton
@onready var _title_label: Label = $Panel/Margin/VBox/Header/Title
@onready var _master_slider: HSlider = $Panel/Margin/VBox/SettingsGrid/MasterSlider
@onready var _music_slider: HSlider = $Panel/Margin/VBox/SettingsGrid/MusicSlider
@onready var _sfx_slider: HSlider = $Panel/Margin/VBox/SettingsGrid/SfxSlider
@onready var _fullscreen_check: CheckBox = $Panel/Margin/VBox/SettingsGrid/FullscreenCheck
@onready var _fast_mode_check: CheckBox = $Panel/Margin/VBox/SettingsGrid/FastModeCheck

var _closing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_title_label.text = title_text
	_layout_overlay()
	resized.connect(_layout_overlay)
	_load_settings()
	_connect_controls()
	call_deferred("_layout_overlay")


func _connect_controls() -> void:
	_close_button.pressed.connect(close)
	_dismiss_button.pressed.connect(close)
	_master_slider.value_changed.connect(func(_value): _apply_audio_settings())
	_music_slider.value_changed.connect(func(_value): _apply_audio_settings())
	_sfx_slider.value_changed.connect(func(_value): _apply_audio_settings())
	_master_slider.drag_ended.connect(func(_changed): _save_settings())
	_music_slider.drag_ended.connect(func(_changed): _save_settings())
	_sfx_slider.drag_ended.connect(func(_changed): _save_settings())
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_fast_mode_check.toggled.connect(_on_fast_mode_toggled)


func _load_settings() -> void:
	var master_value := _get_bus_value(_find_bus(["Master"]))
	var music_value := _get_bus_value(_find_bus(["Music", "BGM", "music", "bgm"]))
	var sfx_value := _get_bus_value(_find_bus(["SFX", "Sfx", "sfx"]))
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		master_value = config.get_value("Audio", "master", master_value)
		music_value = config.get_value("Audio", "bgm", music_value)
		sfx_value = config.get_value("Audio", "sfx", sfx_value)
	elif Engine.has_meta("ui_master"):
		master_value = Engine.get_meta("ui_master")
		music_value = Engine.get_meta("ui_bgm", music_value)
		sfx_value = Engine.get_meta("ui_sfx", sfx_value)
	_master_slider.set_value_no_signal(clampf(master_value, 0.0, 1.0))
	_music_slider.set_value_no_signal(clampf(music_value, 0.0, 1.0))
	_sfx_slider.set_value_no_signal(clampf(sfx_value, 0.0, 1.0))
	var mode := DisplayServer.window_get_mode()
	_fullscreen_check.set_pressed_no_signal(
		mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)
	_fast_mode_check.set_pressed_no_signal(Engine.time_scale > 1.0)
	_apply_audio_settings()


func _apply_audio_settings() -> void:
	var master_index := _find_bus(["Master"])
	var music_index := _find_bus(["Music", "BGM", "music", "bgm"])
	var sfx_index := _find_bus(["SFX", "Sfx", "sfx"])
	_set_bus_value(master_index, _master_slider.value)
	_set_bus_value(music_index, _child_bus_value(music_index, _music_slider.value))
	_set_bus_value(sfx_index, _child_bus_value(sfx_index, _sfx_slider.value))


func _child_bus_value(bus_index: int, value: float) -> float:
	if bus_index != -1 and AudioServer.get_bus_send(bus_index) == "Master":
		return value
	return _master_slider.value * value


func _set_bus_value(bus_index: int, value: float) -> void:
	if bus_index == -1:
		return
	var safe_value := maxf(value, 0.0001)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(safe_value))
	AudioServer.set_bus_mute(bus_index, value <= 0.0001)


func _get_bus_value(bus_index: int) -> float:
	if bus_index == -1:
		return 1.0
	if AudioServer.is_bus_mute(bus_index):
		return 0.0
	return clampf(db_to_linear(AudioServer.get_bus_volume_db(bus_index)), 0.0, 1.0)


func _find_bus(candidates: Array[String]) -> int:
	for bus_name in candidates:
		var index := AudioServer.get_bus_index(bus_name)
		if index != -1:
			return index
	return -1


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("Audio", "master", _master_slider.value)
	config.set_value("Audio", "bgm", _music_slider.value)
	config.set_value("Audio", "sfx", _sfx_slider.value)
	config.save(CONFIG_PATH)
	Engine.set_meta("ui_master", _master_slider.value)
	Engine.set_meta("ui_bgm", _music_slider.value)
	Engine.set_meta("ui_sfx", _sfx_slider.value)


func _on_fullscreen_toggled(enabled: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		if enabled
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	call_deferred("_layout_overlay")


func _on_fast_mode_toggled(enabled: bool) -> void:
	Engine.time_scale = 1.5 if enabled else 1.0


func close() -> void:
	if _closing:
		return
	_closing = true
	_save_settings()
	get_tree().paused = false
	closed.emit()
	queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if get_tree():
		get_tree().paused = false


func _layout_overlay() -> void:
	var viewport_size := get_viewport_rect().size
	_panel.position = Vector2(viewport_size.x * 0.29, viewport_size.y * 0.17)
	_panel.size = Vector2(viewport_size.x * 0.42, viewport_size.y * 0.66)
