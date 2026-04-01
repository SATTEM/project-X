extends Node2D
class_name Card

signal played(card_instance: Card)

@export var card_resource: CardResource

var effects: Array[Callable] = []
var card_name:
	get:
		return card_resource.card_name


func _ready() -> void:
	BattleManager.register_card(self)
	
	effects = card_resource.transeffects()
	#按钮
	#var button = Button.new()
	#button.size = Vector2(100, 100)
	#add_child(button)
	#点击
	#button.pressed.connect(clicked)
	#var card_image = Sprite2D.new()


func _process(delta: float) -> void:
	pass

func play_card_on_target(target: Character):
	print("Played card: [" + card_name+"] at: [" + target.name + "]")
	for effect in effects:
		effect.call(target)


#func clicked():
	#print("你点击了卡牌。")				
