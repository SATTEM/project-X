class_name Character
extends Node
## 角色脚本

signal draw_required(count: int)
signal character_died(character: Character)
signal turn_ended(character: Character)
signal block_changed(new_block: int)
signal energy_changed(new_energy: int)
signal health_changed(new_health: int)

var hand: Array[Card] #手牌
var health: int
var max_health: int
var energy: int
var max_energy: int
var sprite: Sprite2D #立绘
var block_max: int = 999 #最大格挡值
var block: int = 0: #当前格挡值
	set(value):
		block = max(0, value)
		block_changed.emit(block)
	
func add_block(amount: int) -> void:
	block += amount

func _ready() -> void:
	BattleManager.register_character(self, true)
	max_energy = 3 
	max_health = 80
	health = max_health
	return

func start_turn() -> void:
	## 开始回合：重置能量，尝试抽牌等
	energy = max_energy
	draw_required.emit(5)
	# 自动打出第一张牌
	play_card(hand[0])
	turn_ended.emit(self)
	return

func take_damage(amount: int) -> void:
	## 受击扣血：先扣格挡值,格挡值减少0再减少角色血量，若血量低于0则设置为0并发出角色死亡信号
	if block >= amount:
		block -= amount 
	else:
		health -= amount - block
		block = 0
	health_changed.emit(health)
	if health <= 0:
		health = 0
		character_died.emit(self)

func is_energy_enough(need: int) -> bool:
	## 检查费用：检查角色是否有足够能量
	return energy >= need

func spend_energy(need: int) -> void:
	# 扣除费用：扣除能量
	energy -= need
	if energy < 0:   
		energy = 0  
	energy_changed.emit(energy)
	return

func play_card(card: Card) -> void:
	# 打出手牌：检查是否能打出，若能则扣费打出、调用其打牌方法
	if is_energy_enough(card.cost):
		spend_energy(card.cost)
		card.play()
		hand.erase(card)
	else:
		print("能量不足,无法打出卡牌")
	return
