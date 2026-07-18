extends Node2D
## 怪物自动注册管理器
## Autoload

# ID-工厂 映射
var _factories: Dictionary[String, BaseMonsterResource] = {}
# 怪物文件夹路径
var paths: Array[String] = [
	"res://assets/resources/monsters/",
]

func _ready() -> void:
	## 扫描并注册指定路径下的所有怪物
	_scan_and_register()


func _scan_and_register() -> void:
	## 扫描并注册
	for path in paths:
		for file_name in ResourceLoader.list_directory(path):
			if not file_name.ends_with(".tres"):
				continue
			var file_path := path.path_join(file_name)
			var resource: Resource = ResourceLoader.load(file_path)
			if resource is BaseMonsterResource:
				var id: String = resource.monster_id
				_factories[id] = resource
				print("Register monster factory: ", id)


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
