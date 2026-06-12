@abstract class_name Character
extends Node2D
## 角色基类脚本
## 提供角色类共有方法

# 动画信号
signal damage_display(character: Character, amount: int) # 受击伤害数字动画
signal block_display(character: Character, amount: int) # 格挡增加数字动画
signal heal_display(character: Character, amount: int) # 治疗数字动画

# 数据变动信号
signal character_died(character: Character)
signal turn_ended(character: Character)
signal block_changed(character: Character, new_block: int)
signal health_changed(character: Character, new_health: int)

var hand: Array[Card] #手牌
var is_dead: bool = false
var is_ally: bool = false
var current_row: GlobalEnums.PositionRow
var _health: int = 100 # 幕后生命值变量
var health: int = 100: # 当前生命值
	get: return _health
	set(value):
		_health = min(health_max, max(0, value))
		if is_dead:
			return
		if _health <= 0:
			is_dead = true
			character_died.emit(self)
		health_changed.emit(self, _health)
var health_max: int = 100 # 最大生命值
var block_max: int = 999 # 最大格挡值
var _block: int = 0 # 格挡值幕后变量
var block: int = 0: # 当前格挡值
	get: return _block
	set(value):
		_block = min(block_max, max(0, value))
		block_changed.emit(self, _block)
var world_ui: CharacterWorldUI = null
var buff_pool: Array[BuffResource] = []

@abstract func init() -> void
## 创建角色初始化函数

@abstract func spend_energy(card: Card) -> void
## 扣费方法

@abstract func is_energy_enough(card: Card) -> bool
## 检查能量否足够

func _ready() -> void:
	## 角色节点构造时的共有初始化逻辑，自动执行
	# 清理格挡
	block = 0
	return


func start_turn() -> void:
	## 回合逻辑，应该被派生类重写
	## 重写时，遵循先调用父类逻辑，再调用基类逻辑的顺序(c++ style)
	# 清空格挡
	block = 0
	return


func end_turn() -> void:
	## 结束回合逻辑，应该被派生类所重写
	## 重写时，遵循先执行完自身逻辑，再调用父类逻辑的顺序(c++ style)
	# 回合结束直接把池子里的 Buff 全扔进垃圾桶
	if "buff_pool" in self and not buff_pool.is_empty():
		buff_pool.clear()
		print("回合结束，", self.name, " 的临时增幅已全部清空！")
	# 发射回合结束信号
	turn_ended.emit(self)
	return


func add_block(amount: int) -> void:
	## 添加格挡。此类效果函数标记为(effect), 以后将移动到专门的工具类中
	## 并组合入Character便于调用
	## effect
	block += amount
	block_display.emit(self, amount)


func take_damage(amount: int) -> void:
	## 受击扣血：先扣格挡值,格挡值减少，若为0则再减少角色血量，若血量低于0则设置为0并发出角色死亡信号
	## effect
	var hurt_sfx = "hurt"
	if self is Player:
		hurt_sfx = "hurt_player"
	elif self is Monster and is_ally:
		hurt_sfx = "hurt_ally"
	elif self is Monster:
		hurt_sfx = "hurt_monster"
	AudioManager.play_sfx(hurt_sfx)
	var retain = max(0, amount - block)
	block -= amount
	if retain > 0:
		health -= retain
	damage_display.emit(self, amount)


func heal(amount: int) -> void:
	## 治疗
	# 死人不能被治疗
	if health <= 0:
		return 
	
	var actual_heal = min(amount,health_max - health)
	if actual_heal <= 0:
		return 
	health += actual_heal
	heal_display.emit(self, actual_heal)
		
	print( self.name, " 恢复了 ", actual_heal, " 点生命，当前生命: ", health, "/", health_max)


func process_card_through_buffs(original_card: Card) -> Card:
	## 让打出的卡牌按顺序流经所有的 Buff
	if buff_pool.is_empty():
		return original_card
		
	# 制造一张替身卡牌用于魔改 
	var modified_card = original_card.create_buffed_copy()
	
	# 依次经过增幅池
	for buff in buff_pool:
		modified_card = buff.apply_to_card(modified_card)
		
	return modified_card
