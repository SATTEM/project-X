extends Node2D
## 音频管理器

@export var max_concurrent_sfx: int = 10 # 最大同时播放音效数
@export var min_pitch: float = 0.9
@export var max_pitch: float = 1.1

var _sfx_streams: Dictionary = {}               # 音效名映射到 AudioStream
var _busy_sfx_players: Array[AudioStreamPlayer] = []  # 正在播放的音效
var _idle_sfx_players: Array[AudioStreamPlayer] = []  # 空闲的音效
var _ui_button_sound: String = "button_click"   # 按钮提示音的音效名


func _ready() -> void:
	# 创建独立音频总线
	_setup_audio_buses()
	# 加载所有音效资源
	_load_all_sfx()
	# 预创建AudioStreamPlayer节点池
	_precreate_audio_players()
	# 连接UI按钮提示音
	_connect_ui_sounds()


func _setup_audio_buses() -> void:
	## 创建独立的音频总线便于控制
	pass


func _load_all_sfx() -> void:
	## 加载所有音效
	pass


func _precreate_audio_players() -> void:
	## 创建可供复用的音频播放器
	pass


func _connect_ui_sounds() -> void:
	## 连接UI按钮提示
	pass
