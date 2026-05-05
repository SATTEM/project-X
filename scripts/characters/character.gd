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
var sprite: Sprite2D # 立绘
var block_max: int = 999 # 最大格挡值
var _block: int = 0 # 格挡值幕后变量
var block: int = 0: # 当前格挡值
	get: return _block
	set(value):
		_block = min(block_max, max(0, value))
		block_changed.emit(self, _block)
var body_sprite: Sprite2D = null


@abstract func init() -> void
## 创建角色初始化函数


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
	_play_hit_animation()
	var retain = max(0, amount - block)
	block -= amount
	if retain > 0:
		health -= retain
	damage_display.emit(self, amount)


func heal(amount: int) -> void:
	## 治疗
	## effect
	health += amount
	heal_display.emit(self, amount)


func _play_hit_animation() -> void:
	if not body_sprite:
		return

	# 停止之前的动画
	if has_meta("hit_tween") and get_meta("hit_tween"):
		(get_meta("hit_tween") as Tween).kill()
	
	var tween = create_tween().set_parallel(true)
	set_meta("hit_tween", tween)
	
	# 闪红
	tween.tween_property(body_sprite, "modulate", Color.RED, 0.05)
	tween.tween_property(body_sprite, "modulate", Color.WHITE, 0.15).set_delay(0.05)
	
	# 震动（左右来回，回到原位）
	var orig_pos = position
	tween.tween_property(self, "position", orig_pos + Vector2(8, 0), 0.04)
	tween.tween_property(self, "position", orig_pos - Vector2(8, 0), 0.04).set_delay(0.04)
	tween.tween_property(self, "position", orig_pos, 0.08).set_delay(0.08)
