@abstract class_name BaseMonsterResource
extends Resource
## 抽象怪物工厂

## 共有属性
@export var monster_name: String
@export var health_max: int
@export var energy_elements: Array[GlobalEnums.Element]
@export var energy_overall_max: int = 5
@export var energy_overall_boost: int = 5
@export var monster_scene: PackedScene
@export var monster_id: String
@export var monster_texture: Texture2D
@export var monster_animation_frames: SpriteFrames
@export var display_size: Vector2 = Vector2(200, 200)
## 牌组循环回合数，怪物按此循环抽牌
@export var play_loop_count: int = 1
## 按出现回合组织的牌组字典，Dictionary[int, Array[CardResource]]
## key 为 appear_turn（在循环内的第几回合出现），value 为该回合可抽到的卡牌资源列表
@export var intent_card_map: Dictionary = {}
@export var energy_strategy: MonsterEnergyStrategy
@export var play_strategy: MonsterPlayStrategy


@abstract func create_monster() -> Monster
	## 抽象创建怪物接口
