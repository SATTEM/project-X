extends Node
## 全局卡牌解锁管理器
var _state: UnlockState


func _ready() -> void:
	# 存档存在但为空，也会重新初始化
	_state = SaveManager.load_unlock_state()
	if _state == null or _state.unlocked_ids.is_empty():
		_state = UnlockState.new()
		# 将默认卡牌加入永久解锁池
		var default_cards = Player.get_default_deck_ids()
		for card_id in default_cards:
			if not _state.unlocked_ids.has(card_id):
				_state.unlocked_ids.append(card_id)
		SaveManager.save_unlock_state(_state)


func is_unlocked(unlock_id: String) -> bool:
	## 判断某张卡牌是否已经解锁
	if not _state:
		return false
	return _state.unlocked_ids.has(unlock_id)


func unlock(unlock_id: String) -> void:
	## 解锁一张卡牌
	if not _state:
		_state = UnlockState.new()
	if _state.unlocked_ids.has(unlock_id):
		return
	_state.unlocked_ids.append(unlock_id)
	SaveManager.save_unlock_state(_state)


func get_all_unlocked() -> Array[String]:
	## 收集所有已解锁卡牌
	if not _state:
		return []
	return _state.unlocked_ids.duplicate()
