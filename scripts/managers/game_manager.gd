class_name GameManager
extends Node

func _ready() -> void:
	## 游戏初始化后启动
	BattleManager.start_battle($Player, [$Monster])
