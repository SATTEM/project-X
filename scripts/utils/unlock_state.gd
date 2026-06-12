class_name UnlockState
extends Resource

@export var save_version: int = 1
@export var unlocked_ids: Array[String] = []
 

func get_random_unlocked_cards(count: int) -> Array[String]:
	## 获取一组随机的、玩家已解锁的卡牌 ID
	var available_cards: Array[String] = unlocked_ids # 假设这是你存所有已解锁 ID 的数组
	var result: Array[String] = []
	
	if available_cards.is_empty():
		return result
		
	for i in range(count):
		result.append(available_cards.pick_random())
	return result
