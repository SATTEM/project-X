class_name Monster
extends Character

signal intent_changed(type: String, value: int)

var exist_turn: int = 1
var intent_type: String = "attack"
var intent_value: int = 0
var energy_slots: Dictionary[GlobalEnums.Element, int] = {GlobalEnums.Element.WATER: 1}
var energy_slots_max: Dictionary[GlobalEnums.Element, int]:
	get:
		return monster_resource.energy_slots_max
var monster_resource: MonsterResource
@onready var intent_icon: Sprite2D = $IntentIcon
var intent_textures: Dictionary[String, Texture2D]:
	get:
		return monster_resource.intent_textures


func init() -> void:
	## 进战初始化
	energy_slots = energy_slots_max.duplicate()
	health = health_max
	# 选择出生位置
	if is_ally:
		current_row = GlobalEnums.PositionRow.FRONT
	else:
		current_row = GlobalEnums.PositionRow.ENEMY
	
	choose_intent()
	# 根据意图切换意图图标
	var tex = intent_textures.get(intent_type)
	if tex:
		intent_icon.texture = tex
	else:
		printerr("Missing intent textures!")
		intent_icon.texture = null
	
	print("Monster children: ", get_children())


func start_turn() -> void:
	## 开始回合逻辑
	## 执行意图、根据回合数选择意图并广播
	# 调用父类开始回合逻辑
	super.start_turn()
	exist_turn += 1
	execute_intent()
	# 选择下一回合的意图
	choose_intent()
	intent_changed.emit(intent_type, intent_value)
	# 根据意图切换意图图标
	var tex = intent_textures.get(intent_type)
	if tex:
		intent_icon.texture = tex
	else:
		printerr("Missing intent textures!")
		intent_icon.texture = null
	return


func end_turn() -> void:
	## 结束回合
	# 调用父类结束回合逻辑
	super.end_turn()
	return


func choose_intent() -> void:
	## 选择意图，目前按照固定策略循环，以后要改成按固定牌组循环
	if exist_turn % 2 == 1:
		intent_type = "attack"
		intent_value = 6
	else:
		intent_type = "defend"
		intent_value = 5
	return


func execute_intent() -> void:
	## 执行意图
	var target: Character = BattleManager.get_card_target()
	if not target:
		# 未找到目标，跳过
		return
	if intent_type == "attack" and energy_slots[GlobalEnums.Element.WATER] > 0:
		target.take_damage(intent_value)
		print(name, "attacks ", target.name, "for ", intent_value)
	elif intent_type == "defend" and energy_slots[GlobalEnums.Element.WATER] > 0:
		# 添加格挡
		add_block(intent_value)
		print("Monster defended!")
	return


func play_card(_card: Card) -> void:
	## 打牌函数，暂时是占位符
	pass
