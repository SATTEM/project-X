extends Node2D
## 怪物自动注册管理器
## Autoload

# ID-工厂 映射
var _factories: Dictionary[String, BaseMonsterResource] = {}
# 怪物文件夹路径
var paths: Array[String] = [
	"res://assets/monster_resources/",
]

func _ready() -> void:
	## 扫描并注册指定路径下的所有怪物
	_scan_and_register()


func _scan_and_register() -> void:
	## 扫描并注册
	for path in paths:
		var dir = DirAccess.open(path)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tres"):
					var file_path = path + file_name
					var res = load(file_path)
					if res is BaseMonsterResource:
						var id = res.monster_id
						_factories[id] = res
						print("Register monster factory: ", id)
				file_name = dir.get_next()
			dir.list_dir_end()


func create_monster(monster_id: String) -> Monster:
	## 根据ID创建怪物
	if _factories.has(monster_id):
		return _factories[monster_id].create_monster()
	else:
		printerr("Monster factory not found: ", monster_id)
		return null


func get_all_monster_ids() -> Array[String]:
	## 获取所有已注册怪物的ID
	return _factories.keys()
