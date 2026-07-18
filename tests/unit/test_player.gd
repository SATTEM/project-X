extends GutTest

var player: Player


func before_each() -> void:
	player = autofree(Player.new())
	player.max_energy = 5
	player.energy = 0
	player.max_hand_size = 7


func _make_card(cost: int = 0) -> Card:
	var resource := CardResource.new()
	resource.cost = cost
	var card := Card.new()
	card.card_resource = resource
	return autofree(card)


func test_energy_check_and_spending_never_go_below_zero() -> void:
	var card := _make_card(3)
	player.energy = 4
	watch_signals(player)

	assert_true(player.is_energy_enough(card))
	player.spend_energy(card)
	assert_eq(player.energy, 1)
	assert_signal_emitted_with_parameters(player.energy_changed, [1])

	player.spend_energy(card)
	assert_eq(player.energy, 0)
	assert_signal_emitted_with_parameters(player.energy_changed, [0])


func test_gain_energy_returns_actual_gain_and_caps_at_maximum() -> void:
	player.energy = 3
	watch_signals(player)

	assert_eq(player.gain_energy(4), 2)
	assert_eq(player.energy, 5)
	assert_signal_emitted_with_parameters(player.energy_changed, [5])
	assert_eq(player.gain_energy(1), 0)
	assert_eq(player.gain_energy(-2), 0)
	assert_signal_emit_count(player.energy_changed, 1)


func test_draw_card_respects_hand_limit_and_discards_overflow() -> void:
	player.max_hand_size = 2
	var first := _make_card()
	var second := _make_card()
	var overflow := _make_card()
	player.draw_pile = [first, second, overflow]
	watch_signals(player)

	player.draw_card(3)

	assert_eq(player.hand, [first, second])
	assert_eq(player.draw_pile.size(), 0)
	assert_eq(player.discard_pile, [overflow])
	assert_signal_emitted_with_parameters(player.cards_drawn, [[first, second]])
	assert_signal_emitted_with_parameters(player.hand_limit_exceeded, [1])
	assert_signal_emitted_with_parameters(player.card_discarded, [overflow])


func test_draw_reshuffles_discard_when_draw_pile_is_empty() -> void:
	var first := _make_card()
	var second := _make_card()
	var third := _make_card()
	player.draw_pile = [first]
	player.discard_pile = [second, third]

	player.draw_card(3)

	assert_eq(player.hand.size(), 3)
	assert_has(player.hand, first)
	assert_has(player.hand, second)
	assert_has(player.hand, third)
	assert_true(player.draw_pile.is_empty())
	assert_true(player.discard_pile.is_empty())


func test_discard_updates_pile_and_emits_both_signals() -> void:
	var card := _make_card()
	watch_signals(player)

	player.discard(card)

	assert_eq(player.discard_pile, [card])
	assert_signal_emitted_with_parameters(player.piles_changed, [0, 1])
	assert_signal_emitted_with_parameters(player.card_discarded, [card])


func test_start_turn_resets_block_energy_and_draws_five_cards() -> void:
	for index in range(5):
		player.draw_pile.append(_make_card(index))
	player.block = 9
	player.energy = 1
	watch_signals(player)

	player.start_turn()

	assert_eq(player.block, 0)
	assert_eq(player.energy, player.max_energy)
	assert_eq(player.hand.size(), 5)
	assert_signal_emitted_with_parameters(player.energy_changed, [player.max_energy])
