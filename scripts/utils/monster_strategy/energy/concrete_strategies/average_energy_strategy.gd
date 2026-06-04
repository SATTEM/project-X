class_name AverageEnergyStrategy
extends MonsterEnergyStrategy

## 平均分配能量槽策略
## 将 energy_overall_max 和 energy_overall_boost 平均分配给所有元素类型
func energy_startegy_assign(monster: Monster) -> void:
	var elements = monster.energy_elements
	var count = elements.size()
	if count == 0:
		return
	var total_max = monster.monster_resource.energy_overall_max
	var total_boost = monster.monster_resource.energy_overall_boost

	var base_max = total_max / count
	var base_boost = total_boost/ count
	var remainder_max = total_max % count
	var remainder_boost = total_boost % count

	for i in range(count):
		var elem = elements[i]
		monster.energy_slots_max[elem] = base_max + (1 if i < remainder_max else 0)
		monster.energy_slots_boost[elem] = base_boost + (1 if i < remainder_boost else 0)
