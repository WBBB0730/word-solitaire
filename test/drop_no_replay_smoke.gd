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
	var target_center := Vector2(
		scene._column_x(1) + scene.CARD_W * 0.5,
		scene.BOARD_Y + scene.CARD_H * 0.5
	)
	var local_pos := Vector2(scene.CARD_W * 0.5, scene.CARD_H * 0.5)

	scene._begin_drag_candidate(scene._selection_for_board(0, 0), local_pos, source_center)
	scene._update_drag(local_pos, source_center + Vector2(50, -20))
	scene._finish_drag(target_center)

	var expected_pos := Vector2(scene._column_x(1), scene.BOARD_Y + scene.STACK_STEP)
	var moved_button := _find_visible_card_button(scene, moved_card["id"])
	if moved_button == null:
		push_error("Drop no replay smoke failed: moved card control not found")
		quit(1)
		return false
	if moved_button.position.distance_to(expected_pos) > 0.1:
		push_error("Drop no replay smoke failed: moved card replayed from old position")
		quit(1)
		return false
	print("DROP_NO_REPLAY_SMOKE_PASS")
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
	scene.steps_left = 120
	scene.game_over = false
	scene.status_text = "drop no replay test"
	scene.previous_card_positions.clear()
	scene._render()


func _find_visible_card_button(node: Node, card_id: int) -> Button:
	for child in node.get_children():
		if _has_queued_ancestor(child):
			continue
		if child is Button and child.visible and child.has_meta("card_id") and child.get_meta("card_id") == card_id:
			return child
		var nested := _find_visible_card_button(child, card_id)
		if nested != null:
			return nested
	return null


func _has_queued_ancestor(node: Node) -> bool:
	var current := node
	while current != null:
		if current.is_queued_for_deletion():
			return true
		current = current.get_parent()
	return false
