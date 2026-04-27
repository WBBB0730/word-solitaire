extends SceneTree

var scene: Node
var checked := false


func _initialize() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene._ready()


func _process(_delta: float) -> bool:
	if checked:
		return false
	checked = true
	_load_controlled_drop_level()

	var moved_card: Dictionary = scene.columns[0][0]
	var source_center := Vector2(
		scene._column_x(0) + scene.CARD_W * 0.5,
		scene.BOARD_Y + scene.CARD_H * 0.5
	)
	var target_lower_hitbox := Vector2(
		scene._column_x(1) + scene.CARD_W * 0.5,
		scene.BOARD_Y + scene.CARD_H + scene.BOARD_DROP_EXTRA_BOTTOM - 8.0
	)
	var local_pos := Vector2(scene.CARD_W * 0.5, scene.CARD_H * 0.5)

	scene._begin_drag_candidate(scene._selection_for_board(0, 0), local_pos, source_center)
	scene._update_drag(local_pos, target_lower_hitbox)
	scene._finish_drag(target_lower_hitbox)

	if scene.columns[1].size() != 2 or scene.columns[1][1]["id"] != moved_card["id"]:
		push_error("Board drop extended hitbox smoke failed: lower column area did not accept a valid drop")
		quit(1)
		return false
	if scene.steps_left != 119:
		push_error("Board drop extended hitbox smoke failed: valid lower drop did not consume one step")
		quit(1)
		return false
	print("BOARD_DROP_EXTENDED_HITBOX_SMOKE_PASS")
	quit(0)
	return false


func _load_controlled_drop_level() -> void:
	scene.categories = {
		"水果": ["苹果", "香蕉", "葡萄"],
	}
	scene.next_card_id = 1
	scene.word_to_category.clear()
	for word in scene.categories["水果"]:
		scene.word_to_category[word] = "水果"
	scene.deck.clear()
	scene.draw_stack.clear()
	scene.columns = [
		[scene._word("苹果")],
		[scene._word("香蕉")],
		[],
		[],
	]
	scene.active_categories.clear()
	scene.active_order.clear()
	scene.selected.clear()
	scene.menu_active = false
	scene.steps_left = 120
	scene.game_over = false
	scene.status_text = "board drop extended hitbox test"
	scene.previous_card_positions.clear()
	scene._render()
