class_name NormalEnergyStrategy
extends MonsterEnergyStrategy


func energy_startegy_assign(monster: Monster) -> void:
	## 根据比例分配每个属性的元素点最大值和回复量
	for card in monster.intent_cards:
		monster.energy_slots_max[card.element] += 1
		monster.energy_slots_boost[card.element] += 1
	var max_left = monster.monster_resource.energy_overall_max
	var boost_left = monster.monster_resource.energy_overall_boost
	for element in monster.energy_slots_max:
		var radio: float = monster.energy_slots_max[element] as float / monster.intent_cards.size()
		var max_value := radio * monster.monster_resource.energy_overall_max as int
		var boost_value := radio * monster.monster_resource.energy_overall_boost as int
		if radio > 0 and max_value == 0:
			max_value = 1
		if max_left <= max_value:
			max_value = max_left
		max_left -= max_value
		monster.energy_slots_max[element] = max_value
		
		if radio > 0 and boost_value == 0:
			boost_value = 1
		if boost_left <= boost_value:
			boost_value = boost_left
		boost_left -= boost_value
		monster.energy_slots_boost[element] = boost_value

	if max_left > 0:
		var max_element: GlobalEnums.Element = monster.energy_elements[0]
		for element in monster.energy_elements:
			if monster.energy_slots_max[element] == 0:
				if max_left > 0:
					monster.energy_slots_max[element] += 1
					max_left -= 1
			if monster.energy_slots_max[element] > monster.energy_slots_max[max_element]:
					max_element = element
		if max_left > 0:
			monster.energy_slots_max[max_element] += max_left
	
	if boost_left > 0:
		var max_element: GlobalEnums.Element = monster.energy_elements[0]
		for element in monster.energy_elements:
			if monster.energy_slots_boost[element] == 0:
				if boost_left > 0:
					monster.energy_slots_boost[element] += 1
					boost_left -= 1
			if monster.energy_slots_boost[element] > monster.energy_slots_boost[max_element]:
					max_element = element
		if boost_left > 0:
			monster.energy_slots_boost[max_element] += boost_left
