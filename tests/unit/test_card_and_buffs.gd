extends GutTest


func _make_card(cost: int, effects: Array[EffectResource]) -> Card:
	var resource := CardResource.new()
	resource.cost = cost
	resource.effect_resources = effects
	return autofree(resource.create_card())


func test_card_factory_duplicates_effect_resources_per_card() -> void:
	var damage := DamageEffect.new()
	damage.base_amount = 7
	var resource := CardResource.new()
	resource.effect_resources = [damage]

	var first: Card = autofree(resource.create_card())
	var second: Card = autofree(resource.create_card())

	assert_eq(first.effects[0].base_amount, 7)
	assert_not_same(first.effects[0], damage)
	assert_not_same(first.effects[0], second.effects[0])
	first.effects[0].base_amount = 20
	assert_eq(second.effects[0].base_amount, 7)
	assert_eq(damage.base_amount, 7)


func test_buffed_copy_deep_copies_card_data_and_effects() -> void:
	var damage := DamageEffect.new()
	damage.base_amount = 9
	var original := _make_card(3, [damage])
	original.bound_monster_id = "ash_hound"

	var copy: Card = autofree(original.create_buffed_copy())
	copy.card_resource.cost = 1
	copy.effects[0].base_amount = 14

	assert_not_same(copy.card_resource, original.card_resource)
	assert_not_same(copy.effects[0], original.effects[0])
	assert_eq(copy.bound_monster_id, "ash_hound")
	assert_eq(original.cost, 3)
	assert_eq(original.effects[0].base_amount, 9)


func test_power_buff_changes_only_the_temporary_card() -> void:
	var damage := DamageEffect.new()
	damage.base_amount = 6
	var original := _make_card(2, [damage])
	var player: Player = autofree(Player.new())
	var power := PowerBuff.new()
	power.bonus_damage = 4
	player.add_buff(power)

	var modified: Card = autofree(player.process_card_through_buffs(original))

	assert_not_same(modified, original)
	assert_eq(modified.effects[0].base_amount, 10)
	assert_eq(original.effects[0].base_amount, 6)


func test_cost_reduction_never_creates_negative_cost() -> void:
	var card := _make_card(2, [])
	var reduction := CostReductionBuff.new()
	reduction.cost_reduction = 5

	reduction.apply_to_card(card)

	assert_eq(card.cost, 0)


func test_lifesteal_adds_self_heal_only_to_damage_cards() -> void:
	var damage := DamageEffect.new()
	var damage_card := _make_card(1, [damage])
	var block := BlockEffect.new()
	var block_card := _make_card(1, [block])
	var lifesteal := LifestealBuff.new()
	lifesteal.heal_value = 5

	lifesteal.apply_to_card(damage_card)
	lifesteal.apply_to_card(block_card)

	assert_eq(damage_card.effects.size(), 2)
	assert_true(damage_card.effects[1] is HealEffect)
	assert_eq(damage_card.effects[1].base_amount, 5)
	assert_true(damage_card.effects[1].heal_self)
	assert_eq(block_card.effects.size(), 1)


func test_multicast_duplicates_each_damage_effect() -> void:
	var damage := DamageEffect.new()
	damage.base_amount = 4
	var multi_hit := MultiHitDamageEffect.new()
	multi_hit.damage_per_hit = 2
	multi_hit.hit_count = 3
	var block := BlockEffect.new()
	var card := _make_card(2, [damage, block, multi_hit])
	var multicast := MulticastBuff.new()
	var original_damage := card.effects[0]
	var original_block := card.effects[1]
	var original_multi_hit := card.effects[2]

	multicast.apply_to_card(card)

	assert_eq(card.effects.size(), 5)
	assert_same(card.effects[0], original_damage)
	assert_true(card.effects[0] is DamageEffect)
	assert_true(card.effects[1] is DamageEffect)
	assert_not_same(card.effects[0], card.effects[1])
	assert_true(card.effects[2] is BlockEffect)
	assert_same(card.effects[2], original_block)
	assert_true(card.effects[3] is MultiHitDamageEffect)
	assert_true(card.effects[4] is MultiHitDamageEffect)
	assert_same(card.effects[3], original_multi_hit)
	assert_not_same(card.effects[3], card.effects[4])


func test_base_buff_duration_decrements_once_per_turn() -> void:
	var buff := BuffResource.new()
	buff.duration = 3

	buff.on_turn_end()

	assert_eq(buff.duration, 2)
