extends Node
## 存档管理器

const SAVE_DIR := "user://saves/"
const DEFAULT_SLOT := "default"
const PLAYER_STATE_PREFIX := "player_state_"
const UNLOCKS_FILE := "unlocks.tres"


func _ready() -> void:
	_ensure_save_dir()


func _ensure_save_dir() -> void:
	## 保证存档文件夹存在
	if DirAccess.dir_exists_absolute(SAVE_DIR):
		return
	var err = DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if err != OK:
		printerr("Save dir create failed: ", SAVE_DIR, " err=", err)


func _player_state_path(slot: String) -> String:
	## 返回玩家存档的位置
	return "%s%s%s.tres" % [SAVE_DIR, PLAYER_STATE_PREFIX, slot]


func has_player_state(slot: String = DEFAULT_SLOT) -> bool:
	## 判断是否存在存档
	return FileAccess.file_exists(_player_state_path(slot))


func save_player_state(player_state: PlayerState, slot: String = DEFAULT_SLOT) -> bool:
	## 保存玩家状态
	if not player_state:
		return false
	_ensure_save_dir()
	var path = _player_state_path(slot)
	var err = ResourceSaver.save(player_state, path)
	if err != OK:
		printerr("Save player state failed: ", path, " err=", err)
		return false
	return true


func load_player_state(slot: String = DEFAULT_SLOT) -> PlayerState:
	## 加载玩家状态
	var path = _player_state_path(slot)
	if not FileAccess.file_exists(path):
		return null
	var res = ResourceLoader.load(path)
	if res is PlayerState:
		return res
	printerr("Invalid player state resource: ", path)
	return null


func delete_player_state(slot: String = DEFAULT_SLOT) -> void:
	## 删除玩家存档
	var path = _player_state_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func save_unlock_state(unlock_state: UnlockState) -> bool:
	## 保存解锁情况
	if not unlock_state:
		return false
	_ensure_save_dir()
	var path = SAVE_DIR + UNLOCKS_FILE
	var err = ResourceSaver.save(unlock_state, path)
	if err != OK:
		printerr("Save unlock state failed: ", path, " err=", err)
		return false
	return true


func load_unlock_state() -> UnlockState:
	## 加载解锁情况
	var path = SAVE_DIR + UNLOCKS_FILE
	if not FileAccess.file_exists(path):
		return null
	var res = ResourceLoader.load(path)
	if res is UnlockState:
		return res
	printerr("Invalid unlock state resource: ", path)
	return null


func delete_unlock_state() -> void:
	## 删除解锁情况
	var path = SAVE_DIR + UNLOCKS_FILE
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
