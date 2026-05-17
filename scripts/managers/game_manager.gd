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

@onready var player: Player = $Player


func _ready() -> void:
	AudioManager.play_music("bgm_main")
	BattleManager.battle_finished.connect(_on_battle_finished)
	if auto_start_on_ready:
		start_or_continue_run()


func start_or_continue_run() -> void:
	## 开始游戏
	var loaded = SaveManager.load_player_state()
	# 若有存档且还有战斗则继续，否则新游戏
	if loaded and CampaignManager.has_next_battle(loaded):
		player_state = loaded
		_enter_state(GameState.MAP)
		_start_next_battle()
		return
	SaveManager.delete_player_state()
	start_new_run()


func start_new_run() -> void:
	_start_new_run()
	_enter_state(GameState.MAP)
	_start_next_battle()


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
	if not CampaignManager.has_next_battle(player_state):
		_enter_state(GameState.VICTORY)
		return
	var enemies = CampaignManager.get_next_battle_monsters(player_state)
	if enemies.is_empty():
		_enter_state(GameState.VICTORY)
		return
	BattleManager.start_battle(player, enemies, player_state)
	_enter_state(GameState.BATTLE)


func _on_battle_finished(result: Dictionary) -> void:
	if not player_state:
		return
	player_state.apply_battle_result(result)
	SaveManager.save_player_state(player_state)
	if result.get("victory", false):
		if CampaignManager.has_next_battle(player_state):
			_enter_state(GameState.MAP)
			_start_next_battle()
		else:
			_enter_state(GameState.VICTORY)
	else:
		_enter_state(GameState.DEFEAT)


func _enter_state(new_state: GameState) -> void:
	if state == new_state:
		return
	state = new_state
	game_state_changed.emit(new_state)
