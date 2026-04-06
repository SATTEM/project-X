extends Node2D

class_name Character
var health: int
var max_health: int
var energy: int 
var max_energy: int
var hand: Array = [] #手牌
var sprite: Sprite2D #立绘


signal draw_required(count: int)
signal character_died(character: Character)
signal turn_end(character: Character)

#开始回合：重置能量，尝试抽牌等
func start_turn() -> void:
	energy = max_energy
	draw_required.emit(5)

#受击扣血：减少角色血量，若血量低于0则设置为0并发出角色死亡信号
func take_damage(count: int) -> void:
	health -= count
	if health < 0:
		character_died.emit(self)
	
#检查费用：检查角色是否有足够能量
func is_energy_enough(need: int) -> bool:
	return energy >= need

#扣除费用：扣除能量
func spend_energy(need: int) -> void:
	energy -= need
	if energy < 0:   
		energy = 0  

#打出手牌：检查是否能打出，若能则扣费打出、调用其打牌方法
func play_card(card) -> void: 
	if is_energy_enough:
		spend_energy(card.cost)
		card.played(self)
		hand.erase(self)
	else:
		print("能量不足,无法打出卡牌")
		
