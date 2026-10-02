extends GutTest

var player: Player
var ally: Monster
var enemy: Monster


func before_each() -> void:
	player = autofree(Player.new())
	player.is_ally = true
	ally = autofree(Monster.new())
	ally.is_ally = true
	enemy = autofree(Monster.new())
	enemy.is_ally = false
	BattleManager.player = player


func after_each() -> void:
	BattleManager.player = null


func _make_card(target_type: GlobalEnums.TargetType) -> Card:
	var resource := CardResource.new()
	resource.target_type = target_type
	var card := Card.new()
	card.card_resource = resource
	return autofree(card)


func test_self_target_accepts_only_the_user() -> void:
	var card := _make_card(GlobalEnums.TargetType.SELF)

	assert_true(BattleManager.is_valid_target(card, player, player))
	assert_false(BattleManager.is_valid_target(card, player, ally))


func test_enemy_target_requires_opposite_side() -> void:
	var card := _make_card(GlobalEnums.TargetType.ENEMY)

	assert_true(BattleManager.is_valid_target(card, player, enemy))
	assert_false(BattleManager.is_valid_target(card, player, ally))


func test_ally_target_excludes_the_user() -> void:
	var card := _make_card(GlobalEnums.TargetType.ALLY)

	assert_true(BattleManager.is_valid_target(card, player, ally))
	assert_false(BattleManager.is_valid_target(card, player, player))
	assert_false(BattleManager.is_valid_target(card, player, enemy))


func test_monster_target_accepts_all_monsters() -> void:
	var card := _make_card(GlobalEnums.TargetType.MONSTER)

	assert_true(BattleManager.is_valid_target(card, player, ally))
	assert_true(BattleManager.is_valid_target(card, player, enemy))
	assert_false(BattleManager.is_valid_target(card, player, player))


func test_any_target_accepts_any_character() -> void:
	var card := _make_card(GlobalEnums.TargetType.ANY)

	assert_true(BattleManager.is_valid_target(card, player, player))
	assert_true(BattleManager.is_valid_target(card, player, ally))
	assert_true(BattleManager.is_valid_target(card, player, enemy))


func test_front_line_ally_protects_player_from_enemy_monster() -> void:
	var card := _make_card(GlobalEnums.TargetType.ENEMY)
	assert_true(BattleManager.is_valid_target(card, enemy, player))

	var front_guard: Monster = autofree(Monster.new())
	front_guard.is_ally = true
	var world_ui := CharacterWorldUI.new()
	world_ui.name = "CharacterWorldUI"
	front_guard.add_child(world_ui)
	BattleManager.position_rows[GlobalEnums.PositionRow.FRONT].add_child(front_guard)

	assert_false(BattleManager.is_valid_target(card, enemy, player))
	assert_true(BattleManager.is_valid_target(card, enemy, front_guard))
