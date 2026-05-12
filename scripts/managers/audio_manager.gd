extends Node2D
## 音频管理器

@export var max_concurrent_sfx: int = 10 # 最大同时播放音效数
@export var min_pitch: float = 0.9
@export var max_pitch: float = 1.1

enum Bus {
	MASTER,
	MUSIC,
	SFX
}
const SFX_PATHS = {
	"card_play": "res://assets/sounds/card_play.wav",
	"victory": "res://assets/sounds/victory.wav",
	"defeat": "res://assets/sounds/defeat.wav",
	"button_click": "res://assets/sounds/button_click.wav",
	"bgm_main": "res://assets/sounds/bgm_main.ogg",
	"hurt_monster": "res://assets/sounds/hurt_monster.wav",
	"hurt_player": "res://assets/sounds/hurt_player.wav",
	"hurt_ally": "res://assets/sounds/hurt_ally.wav"
}

var _sfx_streams: Dictionary = {}               # 音效名映射到 AudioStream
var _busy_sfx_players: Array[AudioStreamPlayer] = []  # 正在播放的音效
var _idle_sfx_players: Array[AudioStreamPlayer] = []  # 空闲的音效
var _music_player: AudioStreamPlayer
var _ui_button_sound: String = "button_click"   # 按钮提示音的音效名


func _ready() -> void:
	# 创建独立音频总线
	_setup_audio_buses()
	# 加载所有音效资源
	_load_all_sfx()
	# 预创建AudioStreamPlayer节点池
	_precreate_audio_players()
	# 背景音乐的独立播放器
	_setup_music_player()
	# 连接UI按钮提示音
	_connect_ui_sounds()


func _setup_audio_buses() -> void:
	## 创建独立的音频总线便于控制
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")
	if AudioServer.get_bus_index("Master") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Master")


func _load_all_sfx() -> void:
	## 加载所有音效
	for audio_name in SFX_PATHS:
		var path = SFX_PATHS[audio_name]
		if ResourceLoader.exists(path):
			_sfx_streams[audio_name]= load(path)
		else:
			printerr("音频加载失败：", path)


func _precreate_audio_players() -> void:
	## 创建可供复用的音频播放器
	for i in range(max_concurrent_sfx):
		var player = AudioStreamPlayer.new()
		player.finished.connect(_on_player_finished.bind(player))
		add_child(player)
		_idle_sfx_players.append(player)


func _connect_ui_sounds() -> void:
	_setup_ui_sounds(get_tree().current_scene)


func _setup_ui_sounds(node: Node) -> void:
	if node is BaseButton:
		if not node.pressed.is_connected(_on_button_pressed):
			node.pressed.connect(_on_button_pressed.bind(node))
	for child in node.get_children():
		# 递归处理所有节点
		_setup_ui_sounds(child)


func _on_button_pressed(_button: BaseButton) -> void:
	play_sfx(_ui_button_sound)


func play_sfx(sfx_name: String, bus: Bus = Bus.SFX) -> void:
	if not _sfx_streams.has(sfx_name):
		return
	if _idle_sfx_players.is_empty():
		return
	var player = _idle_sfx_players.pop_back()
	player.stream = _sfx_streams[sfx_name]
	# 随机音高
	player.pitch_scale = randf_range(min_pitch, max_pitch)
	var bus_name = _get_bus_name(bus)
	if AudioServer.get_bus_index(bus_name) != -1:
		player.bus = bus_name
	player.play()
	_busy_sfx_players.append(player)
	
	
func _on_player_finished(player: AudioStreamPlayer) -> void:
	_busy_sfx_players.erase(player)
	player.pitch_scale = 1.0
	_idle_sfx_players.append(player)
	
	
func _setup_music_player() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = _get_bus_name(Bus.MUSIC)
	add_child(_music_player)


func play_music(music_name: String, loop: bool = true) -> void:
	if not _sfx_streams.has(music_name):
		return
	_music_player.stream = _sfx_streams[music_name]
	if loop and _music_player.stream:
		_music_player.stream.loop = true
	_music_player.play()


func stop_music() -> void:
	if _music_player:
		_music_player.stop()


func set_music_volume(volume_db: float) -> void:
	if _music_player:
		_music_player.volume_db = volume_db


func _get_bus_name(bus: Bus) -> String:
	## 获取总线名称
	match bus:
		Bus.MASTER:
			return "Master"
		Bus.MUSIC:
			return "Music"
		Bus.SFX:
			return "SFX"
		_:
			return "Master"
