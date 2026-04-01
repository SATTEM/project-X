class_name Character
extends Node

signal draw_required(count: int)
signal character_died(character: Character)
signal turn_ended(character: Character)

var hand: Array[Card]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	BattleManager.register_player(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func start_turn() -> void:
	print("Character Turn Start!")
	draw_required.emit(1)
	hand[0].played.emit(hand)
	turn_ended.emit(self)
	

func take_damage(value: int):
	print("Character get attacked: " + str(value))
