@abstract class_name BaseMonsterResource
extends Resource
## 抽象怪物工厂

## 共有属性
@export var monster_name: String
@export var health_max: int
@export var energy_slots_max: Dictionary[GlobalEnums.Element, int] = {GlobalEnums.Element.WATER: 2}
@export var monster_scene: PackedScene
@export var monster_id: String
@export var monster_texture: Texture2D
@export var display_size: Vector2 = Vector2(200, 200)
@export var intent_card_resources: Array[CardResource]


@abstract func create_monster() -> Monster
	## 抽象创建怪物接口
