class_name  MonsterResource
extends BaseMonsterResource
## 具体怪物工厂


func create_monster() -> Monster:
	## 创建怪物并初始化
	if not monster_scene:
		printerr("MonsterResource 没有设置 monster_scene")
		return null
	var monster = monster_scene.instantiate()
	monster.monster_resource = self
	monster.health_max = health_max

	return monster
