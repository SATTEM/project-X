@abstract class_name Character
extends Node
## 角色基类脚本
## 提供角色类共有方法

signal drawing(count: int)
signal character_died(character: Character)
signal turn_ended(character: Character)
signal block_changed(new_block: int)
signal health_changed(new_health: int)

var hand: Array[Card] #手牌
var _health: int = 100 # 幕后生命值变量
var health: int = 100: # 当前生命值
	get: return _health
	set(value):
		_health = min(health_max, max(0, value))
		health_changed.emit(_health)
var health_max: int = 100 # 最大生命值
var sprite: Sprite2D # 立绘
var block_max: int = 999 # 最大格挡值
var _block: int = 0 # 格挡值幕后变量
var block: int = 0: # 当前格挡值
	get: return _block
	set(value):
		_block = min(block_max, max(0, value))
		block_changed.emit(_block)



func _ready() -> void:
	## 角色节点构造时的共有初始化逻辑，自动执行
	# 暂无
	return


@abstract func init() -> void ## 创建角色初始化函数


func start_turn() -> void:
	## 开始回合逻辑，应该被派生类重写
	## 重写时，遵循先调用父类逻辑，再调用基类逻辑的顺序(c++ style)
	# 基类暂无回合逻辑
	return


func end_turn() -> void:
	## 结束回合逻辑，应该被派生类所重写
	## 重写时，遵循先执行完自身逻辑，再调用父类逻辑的顺序(c++ style)
	# 发射回合结束信号
	turn_ended.emit(self)
	return


@abstract func play_card(_card: Card) -> void
## 打出卡牌方法，具体实现在派生类中

func add_block(amount: int) -> void:
	## 添加格挡。此类效果函数标记为(effect), 以后将移动到专门的工具类中
	## 并组合入Character便于调用
	## effect
	block += amount


func take_damage(amount: int) -> void:
	## 受击扣血：先扣格挡值,格挡值减少0再减少角色血量，若血量低于0则设置为0并发出角色死亡信号
	## effect
	if block >= amount:
		block -= amount 
	else:
		health -= amount - block
		block = 0
	health_changed.emit(health)
	if health <= 0:
		health = 0
		character_died.emit(self)
