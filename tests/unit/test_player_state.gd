extends GutTest


func test_reset_to_defaults_replaces_all_run_progress() -> void:
	var source_deck: Array[String] = ["attack_card", "defend_card"]
	var state := PlayerState.new()
	state.current_node_id = "old_node"
	state.battles_completed = 4
	state.current_level_index = 3
	state.gold = 500

	state.reset_to_defaults(source_deck, 120)
	source_deck.append("draw_card")

	assert_eq(state.max_hp, 120)
	assert_eq(state.current_hp, 120)
	assert_eq(state.deck_ids, ["attack_card", "defend_card"])
	assert_eq(state.summon_bindings.size(), 2)
	assert_eq(state.current_node_id, "")
	assert_eq(state.battles_completed, 0)
	assert_eq(state.current_level_index, 0)
	assert_eq(state.gold, 99)


func test_battle_result_clamps_health_and_counts_only_victories() -> void:
	var state := PlayerState.new()
	state.max_hp = 80
	state.current_hp = 80

	state.apply_battle_result({"remaining_hp": 120, "victory": false})
	assert_eq(state.current_hp, 80)
	assert_eq(state.battles_completed, 0)

	state.apply_battle_result({"remaining_hp": -5, "victory": true})
	assert_eq(state.current_hp, 0)
	assert_eq(state.battles_completed, 1)


func test_battle_rewards_add_only_string_card_ids() -> void:
	var state := PlayerState.new()
	state.deck_ids = ["attack_card"]
	state.summon_bindings = [""]

	state.apply_battle_result({
		"victory": true,
		"rewards": ["defend_card", 42, "draw_card"],
	})

	assert_eq(state.deck_ids, ["attack_card", "defend_card", "draw_card"])
	assert_eq(state.summon_bindings.size(), state.deck_ids.size())
	assert_eq(state.battles_completed, 1)


func test_remove_card_removes_first_match_and_aligned_binding() -> void:
	var state := PlayerState.new()
	state.deck_ids = ["attack_card", "defend_card", "attack_card"]
	state.summon_bindings = ["first", "middle", "last"]

	assert_true(state.remove_card_from_run_deck("attack_card"))
	assert_eq(state.deck_ids, ["defend_card", "attack_card"])
	assert_eq(state.summon_bindings, ["middle", "last"])
	assert_false(state.remove_card_from_run_deck("missing_card"))


func test_binding_access_repairs_size_and_rejects_invalid_indices() -> void:
	var state := PlayerState.new()
	state.deck_ids = ["attack_card", "defend_card"]
	state.summon_bindings = ["stale", "extra", "extra"]

	assert_eq(state.get_summon_binding(0), "stale")
	assert_eq(state.summon_bindings.size(), 2)
	assert_eq(state.get_summon_binding(-1), "")
	assert_eq(state.get_summon_binding(2), "")
	assert_false(state.set_summon_binding(2, "ash_hound"))
	assert_false(state.set_summon_binding(0, "ash_hound"), "Non-summon cards cannot receive a binding.")
