extends CanvasLayer

@onready var info_label = $Panel/Label
@onready var confirm_btn = $Panel/ConfirmButton
@onready var normal_btn = $Panel/VBoxContainer/NormalButton
@onready var elite_a_btn = $Panel/VBoxContainer/EliteAButton
@onready var elite_b_btn = $Panel/VBoxContainer/EliteBButton

# 三个可选战斗的数据
var battles = {
	"normal": {
		"name": "普通敌人",
		"enemies": ["spider"],
		"reward_gold": 70
	},
	"elite_a": {
		"name": "精英敌人",
		"enemies": ["base", "base"],
		"reward_gold": 100
	},
	"elite_b": {
		"name": "精英敌人",
		"enemies": ["baset", "base"],
		"reward_gold": 100
	}
}

# 默认
var selected_key = "normal"
var game_manager: GameManager

func set_game_manager(gm):
	game_manager = gm


func _ready():
	normal_btn.pressed.connect(_on_normal)
	elite_a_btn.pressed.connect(_on_elite_a)
	elite_b_btn.pressed.connect(_on_elite_b)
	confirm_btn.pressed.connect(_on_confirm)
	_update_info()


func _on_normal():
	selected_key = "normal"
	_update_info()


func _on_elite_a():
	selected_key = "elite_a"
	_update_info()


func _on_elite_b():
	selected_key = "elite_b"
	_update_info()


func _update_info():
	var data = battles[selected_key]
	info_label.text = "下一场： %s" % data["name"]


func _on_confirm():
	var data = battles[selected_key]
	if game_manager:
		game_manager._on_rest_battle_selected(data["enemies"], data["reward_gold"])
	queue_free()
