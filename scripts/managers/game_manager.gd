class_name GameManager
extends Node2D
## 游戏管理器，采用状态机流转

signal game_state_changed(new_state: GameState)

enum GameState {
	BOOT,
	MAIN_MENU,
	MAP,
	BATTLE,
	VICTORY,
	DEFEAT,
}

@export var auto_start_on_ready: bool = true

var state: GameState = GameState.BOOT
var player_state: PlayerState
var pending_gold_reward: int = 0

@onready var player: Player = $Player
@onready var battle_ui: Control = $UIContainer/BattleUI


func _ready() -> void:
	AudioManager.play_music("bgm_main")
	BattleManager.battle_finished.connect(_on_battle_finished)
	if auto_start_on_ready:
		start_or_continue_run()


func start_or_continue_run() -> void:
	## 开始游戏
	var loaded = SaveManager.load_player_state()
	# 若有存档且还有战斗则继续，否则新游戏
	if loaded and CampaignManager.has_next_level(loaded):
		player_state = loaded
		_enter_state(GameState.MAP)
		_start_next_battle()
		return
	SaveManager.delete_player_state()
	start_new_run()


func start_new_run() -> void:
	_start_new_run()
	_enter_state(GameState.MAP)
	CampaignManager.init_campaign()
	_process_current_level()


func _process_current_level():
	print("处理关卡，当前索引：", player_state.current_level_index)
	var level = CampaignManager.get_current_level(player_state)
	print("当前关卡类型：", level.level_type if level else "null")
	if level == null:
		_enter_state(GameState.VICTORY)
		return
	match level.level_type:
		"battle":
			_start_next_battle()
		"rest":
			_open_rest_area()
		"shop":
			_open_shop()


func reset_game() -> void:
	## 清档并重开
	SaveManager.delete_player_state()
	start_new_run()


func _start_new_run() -> void:
	player_state = PlayerState.new()
	player_state.reset_to_defaults(Player.get_default_deck_ids(), player.health_max)
	SaveManager.save_player_state(player_state)


func _start_next_battle() -> void:
	## 开始下一场战斗
	if not player_state:
		return
	var level = CampaignManager.get_current_level(player_state)
	if not level is BattleLevel:
		return
	var battle_level = level as BattleLevel
	if battle_level.enemies.is_empty():
		return
	pending_gold_reward = battle_level.reward_gold
	var monsters: Array[Monster] = []
	for id in battle_level.enemies:
		var m = MonsterLibrary.create_monster(id)
		if m:
			monsters.append(m)
	BattleManager.start_battle(player, monsters, player_state)
	_enter_state(GameState.BATTLE)


func _on_battle_finished(result: Dictionary) -> void:
	if not player_state:
		return
	player_state.apply_battle_result(result)
	SaveManager.save_player_state(player_state)
	if result.get("victory", false):
		add_gold(pending_gold_reward)
		CampaignManager.advance_to_next_level(player_state)
		_process_current_level()
	else:
		_enter_state(GameState.DEFEAT)


func _open_rest_area():
	print("打开休息处")
	var rest_scene = preload("res://scenes/ui/rest_area.tscn").instantiate()
	rest_scene.set_game_manager(self)
	add_child(rest_scene)


func _open_shop():
	var level = CampaignManager.get_current_level(player_state)
	if level is ShopLevel:
		var shop = preload("res://scenes/ui/shop_scene.tscn").instantiate()
		shop.setup(level)
		add_child(shop)
		shop.shop_closed.connect(_on_shop_closed)


static func spend_gold(amount: int) -> bool:
	## 购买商品
	var current_player_state = SaveManager.load_player_state()
	if current_player_state.gold >= amount:
		current_player_state.gold -= amount
		SaveManager.save_player_state(current_player_state)
		return true
	return false


func add_gold(amount: int):
	if player_state:
		player_state.gold += amount
		SaveManager.save_player_state(player_state)


func _on_shop_closed():
	CampaignManager.advance_to_next_level(player_state)
	_process_current_level()


func _on_rest_battle_selected(enemy_ids, reward_gold):
	var next_battle = CampaignManager.get_next_battle_level(player_state)
	if next_battle and next_battle is BattleLevel:
		next_battle.set_enemies(enemy_ids)
		next_battle.reward_gold = reward_gold
	CampaignManager.advance_to_next_level(player_state)
	_process_current_level()


func _enter_state(new_state: GameState) -> void:
	if state == new_state:
		return
	state = new_state
	game_state_changed.emit(new_state)
