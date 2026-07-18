extends GutTest

var player: Player
var original_sfx_streams: Dictionary


func before_all() -> void:
	original_sfx_streams = AudioManager._sfx_streams
	AudioManager._sfx_streams = {}


func after_all() -> void:
	AudioManager._sfx_streams = original_sfx_streams


func before_each() -> void:
	player = autofree(Player.new())
	player.health_max = 100
	player.is_dead = false
	player.health = 100
	player.block = 0


func test_health_is_clamped_and_death_is_emitted() -> void:
	watch_signals(player)

	player.health = 150
	assert_eq(player.health, 100)
	assert_signal_emitted_with_parameters(player.health_changed, [player, 100])

	player.health = -10
	assert_eq(player.health, 0)
	assert_true(player.is_dead)
	assert_signal_emitted_with_parameters(player.character_died, [player])
	assert_signal_emit_count(player.character_died, 1)


func test_damage_consumes_block_before_health() -> void:
	player.health = 40
	player.block = 6
	watch_signals(player)

	player.take_damage(10)

	assert_eq(player.block, 0)
	assert_eq(player.health, 36)
	assert_signal_emitted_with_parameters(player.damage_display, [player, 10])


func test_block_absorbs_damage_completely() -> void:
	player.health = 40
	player.block = 12

	player.take_damage(7)

	assert_eq(player.block, 5)
	assert_eq(player.health, 40)


func test_heal_caps_at_maximum_and_reports_actual_amount() -> void:
	player.health = 92
	watch_signals(player)

	player.heal(20)

	assert_eq(player.health, 100)
	assert_signal_emitted_with_parameters(player.heal_display, [player, 8])
	player.heal(5)
	assert_signal_emit_count(player.heal_display, 1)


func test_dead_character_cannot_be_healed() -> void:
	player.health = 0
	watch_signals(player)

	player.heal(20)

	assert_eq(player.health, 0)
	assert_signal_not_emitted(player.heal_display)


func test_block_is_clamped_to_valid_range() -> void:
	player.block_max = 20

	player.add_block(30)
	assert_eq(player.block, 20)

	player.block = -5
	assert_eq(player.block, 0)


func test_turn_end_decrements_and_removes_expired_buffs() -> void:
	var expiring := BuffResource.new()
	expiring.buff_name = "expiring"
	expiring.duration = 1
	var lasting := BuffResource.new()
	lasting.buff_name = "lasting"
	lasting.duration = 2
	player.add_buff(expiring)
	player.add_buff(lasting)

	player.process_buffs_on_turn_end()

	assert_eq(player.buff_pool.size(), 1)
	assert_eq(player.buff_pool[0].buff_name, "lasting")
	assert_eq(player.buff_pool[0].duration, 1)
	assert_eq(expiring.duration, 1, "The source resource must not be mutated.")
	assert_eq(lasting.duration, 2, "The source resource must not be mutated.")
