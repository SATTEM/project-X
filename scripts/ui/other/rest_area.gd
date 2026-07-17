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
	## 各难度只从 Settings 中对应的怪物池抽取。
	battles["easy"]["enemies"] = _pick_enemies(Settings.easy_enemy_pool, 1)
	battles["normal"]["enemies"] = _pick_enemies(Settings.normal_enemy_pool, 2)
	# 商店后的困难路线固定为 Boss；其它休息区只提供精英怪。
	if game_manager and CampaignManager.is_boss_rest(game_manager.player_state):
		battles["hard"]["name"] = "首领"
		battles["hard"]["reward_gold"] = 250
		var boss_pool: Array[String] = [Settings.boss_enemy_id]
		battles["hard"]["enemies"] = _pick_enemies(boss_pool, 1)
		elite_b_btn.text = "首领挑战"
		elite_b_btn.tooltip_text = "商店后的固定首领战，奖励金币 x250"
	else:
		var elite_pool: Array[String] = []
		for monster_id in Settings.hard_enemy_pool:
			if monster_id != Settings.boss_enemy_id:
				elite_pool.append(monster_id)
		battles["hard"]["name"] = "精英"
		battles["hard"]["reward_gold"] = 150
		battles["hard"]["enemies"] = _pick_enemies(elite_pool, 1)
		elite_b_btn.text = "精英挑战"
		elite_b_btn.tooltip_text = "高强度精英战，奖励金币 x150"


func _pick_enemies(configured_pool: Array[String], count: int) -> Array[String]:
	var registered_ids := MonsterLibrary.get_all_monster_ids()
	var valid_pool: Array[String] = []
	for monster_id in configured_pool:
		if registered_ids.has(monster_id):
			valid_pool.append(monster_id)

	if valid_pool.is_empty():
		push_warning("配置的怪物池为空或 ID 无效，使用 base 作为兜底敌人。")
		valid_pool = ["base"]

	var result: Array[String] = []
	var available := valid_pool.duplicate()
	while result.size() < count:
		if available.is_empty():
			available = valid_pool.duplicate()
		var selected: String = available.pick_random()
		result.append(selected)
		available.erase(selected)
	return result


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
