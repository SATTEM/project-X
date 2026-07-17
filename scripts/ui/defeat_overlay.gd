class_name DefeatOverlay
extends CanvasLayer

signal restart_requested
signal main_menu_requested

@onready var root: Control = $Root
@onready var dimmer: ColorRect = $Root/Dimmer
@onready var panel: PanelContainer = $Root/Center/Panel
@onready var layer_value: Label = $Root/Center/Panel/Margin/Content/Stats/LayerValue
@onready var gold_value: Label = $Root/Center/Panel/Margin/Content/Stats/GoldValue
@onready var restart_button: Button = $Root/Center/Panel/Margin/Content/Buttons/RestartButton
@onready var main_menu_button: Button = $Root/Center/Panel/Margin/Content/Buttons/MainMenuButton

var _reached_layer: int = 1
var _collected_gold: int = 0
var _action_requested: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.pressed.connect(_request_restart)
	main_menu_button.pressed.connect(_request_main_menu)
	root.resized.connect(_center_panel_pivot)
	_update_summary()
	get_tree().paused = true
	_play_intro()
	restart_button.grab_focus()


func setup(reached_layer: int, collected_gold: int) -> void:
	_reached_layer = maxi(reached_layer, 1)
	_collected_gold = maxi(collected_gold, 0)
	if is_node_ready():
		_update_summary()


func _update_summary() -> void:
	layer_value.text = "抵达层数\n第 %d 层" % _reached_layer
	gold_value.text = "持有金币\n%d" % _collected_gold


func _play_intro() -> void:
	dimmer.modulate.a = 0.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.94, 0.94)
	call_deferred("_center_panel_pivot")
	var tween := create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(dimmer, "modulate:a", 1.0, 0.2)
	tween.tween_property(panel, "modulate:a", 1.0, 0.28)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _center_panel_pivot() -> void:
	panel.pivot_offset = panel.size * 0.5


func _request_restart() -> void:
	if _action_requested:
		return
	_action_requested = true
	_set_buttons_disabled(true)
	AudioManager.play_sfx("button_click")
	restart_requested.emit()


func _request_main_menu() -> void:
	if _action_requested:
		return
	_action_requested = true
	_set_buttons_disabled(true)
	AudioManager.play_sfx("button_click")
	main_menu_requested.emit()


func _set_buttons_disabled(disabled: bool) -> void:
	restart_button.disabled = disabled
	main_menu_button.disabled = disabled


func _exit_tree() -> void:
	if get_tree():
		get_tree().paused = false
