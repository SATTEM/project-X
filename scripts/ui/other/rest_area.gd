extends CanvasLayer

@onready var info_label = $Panel/Label
@onready var confirm_btn = $Panel/ConfirmButton
@onready var normal_btn = $Panel/VBoxContainer/NormalButton
@onready var elite_a_btn = $Panel/VBoxContainer/EliteAButton
@onready var elite_b_btn = $Panel/VBoxContainer/EliteBButton

# 三个可选战斗的数据，敌人从怪物库中动态获取
var battles = {
	"easy": {
		"name": "简单",
		"enemies": [],
		"reward_gold": 50
	},
	"normal": {
		"name": "普通",
		"enemies": [],
		"reward_gold": 100
	},
	"hard": {
		"name": "困难",
		"enemies": [],
		"reward_gold": 150
	}
}

# 默认选中普通难度
var selected_key = "normal"
var game_manager: GameManager

func set_game_manager(gm):
	game_manager = gm


func _ready():
	_init_enemies()
	normal_btn.pressed.connect(_on_normal)
	elite_a_btn.pressed.connect(_on_elite_a)
	elite_b_btn.pressed.connect(_on_elite_b)
	confirm_btn.pressed.connect(_on_confirm)
	_update_info()


func _init_enemies():
	## 从怪物库中动态获取敌人，按难度分配数量
	var all_ids = MonsterLibrary.get_all_monster_ids()
	if all_ids.is_empty():
		all_ids = ["base"]
	# 简单：1个敌人；普通：2个；困难：3个
	battles["easy"]["enemies"] = [all_ids.pick_random()]
	battles["normal"]["enemies"] = [all_ids.pick_random(), all_ids.pick_random()]
	battles["hard"]["enemies"] = [all_ids.pick_random(), all_ids.pick_random(), all_ids.pick_random()]


func _on_normal():
	selected_key = "easy"
	_update_info()


func _on_elite_a():
	selected_key = "normal"
	_update_info()


func _on_elite_b():
	selected_key = "hard"
	_update_info()


func _update_info():
	var data = battles[selected_key]
	info_label.text = "难度：%s（%d 个敌人，+%d 金币）" % [data["name"], data["enemies"].size(), data["reward_gold"]]


func _on_confirm():
	var data = battles[selected_key]
	if game_manager:
		game_manager._on_rest_battle_selected(data["enemies"], data["reward_gold"])
	queue_free()
