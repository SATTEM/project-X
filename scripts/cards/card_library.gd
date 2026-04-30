extends Node2D
## 卡牌自动注册管理器
## Autoload

# ID-工厂 映射
var _factories: Dictionary[String, BaseCardFactory] = {}
# 卡牌文件夹路径
var paths: Array[String] = [
	"res://assets/card_resources/",
]

func _ready() -> void:
	## 扫描并注册指定路径下的所有卡牌
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
					if res is BaseCardFactory:
						# 自注册ID
						var id = res.card_id
						if _factories.has(id):
							printerr("Duplicate card/monster ID: ", id)
						_factories[id] = res
						print("Register card factory: ", id)
				file_name = dir.get_next()
			dir.list_dir_end()


func create_card(card_id: String) -> Card:
	## 根据ID创建卡牌
	if _factories.has(card_id):
		return _factories[card_id].create_card()
	else:
		printerr("Card factory not found: ", card_id)
		return null


func create_card_and_add_to_scene(card_id: String, parent: Node) -> Card:
	var card = create_card(card_id)
	if card:
		parent.add_child(card)
	return card


func get_all_card_ids() -> Array[String]:
	## 获取所有已注册卡牌的ID
	return _factories.keys()
