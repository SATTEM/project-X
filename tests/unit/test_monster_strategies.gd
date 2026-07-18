extends GutTest


func _make_element_card(target_type: GlobalEnums.TargetType) -> ElementCard:
	var resource := CardResource.new()
	resource.target_type = target_type
	var card := ElementCard.new()
	card.card_resource = resource
	return autofree(card)


func _make_monster(elements: Array[GlobalEnums.Element]) -> Monster:
	var resource := MonsterResource.new()
	resource.energy_elements = elements
	var monster := Monster.new()
	monster.monster_resource = resource
	for element in elements:
		monster.energy_slots_max[element] = 0
		monster.energy_slots_boost[element] = 0
		monster.energy_slots[element] = 0
	return autofree(monster)


func _dictionary_total(values: Dictionary) -> int:
	var total := 0
	for value in values.values():
		total += int(value)
	return total


func test_fifo_selects_first_card_and_handles_empty_hand() -> void:
	var first := _make_element_card(GlobalEnums.TargetType.ENEMY)
	var second := _make_element_card(GlobalEnums.TargetType.SELF)
	var hand: Array[ElementCard] = [first, second]
	var empty: Array[ElementCard] = []
	var strategy := FIFOStrategy.new()

	assert_same(strategy.select_card(hand, null), first)
	assert_null(strategy.select_card(empty, null))


func test_selfish_strategy_uses_target_priority() -> void:
	var ally := _make_element_card(GlobalEnums.TargetType.ALLY)
	var enemy := _make_element_card(GlobalEnums.TargetType.ENEMY)
	var self_card := _make_element_card(GlobalEnums.TargetType.SELF)
	var any := _make_element_card(GlobalEnums.TargetType.ANY)
	var hand: Array[ElementCard] = [ally, enemy, any, self_card]

	assert_same(SelfishStrategy.new().select_card(hand, null), self_card)


func test_selfless_strategy_uses_target_priority() -> void:
	var enemy := _make_element_card(GlobalEnums.TargetType.ENEMY)
	var any := _make_element_card(GlobalEnums.TargetType.ANY)
	var ally := _make_element_card(GlobalEnums.TargetType.ALLY)
	var self_card := _make_element_card(GlobalEnums.TargetType.SELF)
	var hand: Array[ElementCard] = [enemy, any, self_card, ally]

	assert_same(SelflessStrategy.new().select_card(hand, null), ally)


func test_average_energy_strategy_distributes_totals_and_remainders() -> void:
	var elements: Array[GlobalEnums.Element] = [
		GlobalEnums.Element.FIRE,
		GlobalEnums.Element.WATER,
		GlobalEnums.Element.SOIL,
	]
	var monster := _make_monster(elements)
	monster.monster_resource.energy_overall_max = 8
	monster.monster_resource.energy_overall_boost = 5

	AverageEnergyStrategy.new().energy_startegy_assign(monster)

	assert_eq(monster.energy_slots_max[GlobalEnums.Element.FIRE], 3)
	assert_eq(monster.energy_slots_max[GlobalEnums.Element.WATER], 3)
	assert_eq(monster.energy_slots_max[GlobalEnums.Element.SOIL], 2)
	assert_eq(monster.energy_slots_boost[GlobalEnums.Element.FIRE], 2)
	assert_eq(monster.energy_slots_boost[GlobalEnums.Element.WATER], 2)
	assert_eq(monster.energy_slots_boost[GlobalEnums.Element.SOIL], 1)
	assert_eq(_dictionary_total(monster.energy_slots_max), 8)
	assert_eq(_dictionary_total(monster.energy_slots_boost), 5)


func test_average_energy_strategy_handles_monster_without_elements() -> void:
	var elements: Array[GlobalEnums.Element] = []
	var monster := _make_monster(elements)
	monster.monster_resource.energy_overall_max = 8

	AverageEnergyStrategy.new().energy_startegy_assign(monster)

	assert_true(monster.energy_slots_max.is_empty())
	assert_true(monster.energy_slots_boost.is_empty())


func test_normal_energy_strategy_preserves_configured_totals() -> void:
	var elements: Array[GlobalEnums.Element] = [
		GlobalEnums.Element.FIRE,
		GlobalEnums.Element.WATER,
		GlobalEnums.Element.SOIL,
	]
	var monster := _make_monster(elements)
	monster.monster_resource.energy_overall_max = 5
	monster.monster_resource.energy_overall_boost = 4
	var fire_one := _make_element_card(GlobalEnums.TargetType.ENEMY)
	var fire_two := _make_element_card(GlobalEnums.TargetType.ENEMY)
	var water := _make_element_card(GlobalEnums.TargetType.ENEMY)
	fire_one.element = GlobalEnums.Element.FIRE
	fire_two.element = GlobalEnums.Element.FIRE
	water.element = GlobalEnums.Element.WATER
	monster.card_pool = {1: [fire_one, fire_two, water]}

	NormalEnergyStrategy.new().energy_startegy_assign(monster)

	assert_eq(_dictionary_total(monster.energy_slots_max), 5)
	assert_eq(_dictionary_total(monster.energy_slots_boost), 4)
	assert_true(monster.energy_slots_max[GlobalEnums.Element.FIRE] >= monster.energy_slots_max[GlobalEnums.Element.WATER])
	assert_true(monster.energy_slots_boost[GlobalEnums.Element.FIRE] >= monster.energy_slots_boost[GlobalEnums.Element.WATER])
