class_name GameManager
extends Node2D

func _ready() -> void:
	## 游戏初始化后启动
	var monster = MonsterLibrary.create_monster("base")
	BattleManager.start_battle($Player, [monster])
