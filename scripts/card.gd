extends Node2D
class_name Card

signal played(card_instance: Card)

@export var card_resource: CardResource

var effects: Array[Callable] = []

func _ready():
	effects = card_resource.transeffects()
	#按钮
	#var button = Button.new()
	#button.size = Vector2(100, 100)
	#add_child(button)
	#点击
	#button.pressed.connect(clicked)
	#var card_image = Sprite2D.new()

func play_card_on_target(target: Character):
	print("打出卡牌:[" + card_resource.card_name+"]")
	for effect in effects:
		effect.call(target)
	played.emit(self)	

#func clicked():
	#print("你点击了卡牌。")				
