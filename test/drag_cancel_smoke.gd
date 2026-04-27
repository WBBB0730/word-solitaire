extends SceneTree

var scene: Node
var capture_mode := false
var frames := 0
var started := false
var source_positions := {}


func _initialize() -> void:
	capture_mode = OS.get_cmdline_user_args().has("--capture")
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene._ready()


func _process(_delta: float) -> bool:
	frames += 1
	if not started:
		started = true
		_load_controlled_multi_card_level()
		_start_invalid_drag()
		_assert_cancel_animation_started()
		if not capture_mode:
			scene._finish_drag_cancel_animation()
			_assert_cancel_animation_finished()
			print("DRAG_CANCEL_SMOKE_PASS")
			quit(0)
		return false
	if capture_mode and frames > 10:
		quit(0)
	return false


func _start_invalid_drag() -> void:
	var col_idx := 0
	var card_idx := 1
	var selection: Dictionary = scene._selection_for_board(col_idx, card_idx)
	var source_center := Vector2(
		scene._column_x(col_idx) + scene.CARD_W * 0.5,
		scene.BOARD_Y + card_idx * scene.STACK_STEP + scene.CARD_H * 0.5
	)
	var local_pos := Vector2(scene.CARD_W * 0.5, scene.CARD_H * 0.5)
	scene._begin_drag_candidate(selection, local_pos, source_center)
	scene._update_drag(local_pos, source_center + Vector2(74, -58))
	scene._finish_drag(Vector2(330, 650))


func _load_controlled_multi_card_level() -> void:
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
		[scene._word("苹果"), scene._word("香蕉")],
		[],
		[],
		[],
	]
	scene.active_categories.clear()
	scene.active_order.clear()
	scene.selected.clear()
	scene.steps_left = 120
	scene.game_over = false
	scene.status_text = "drag cancel test"
	source_positions.clear()
	for card_idx in range(scene.columns[0].size()):
		var card: Dictionary = scene.columns[0][card_idx]
		card["face_up"] = true
		source_positions[card["id"]] = Vector2(scene._column_x(0), scene.BOARD_Y + card_idx * scene.STACK_STEP)
	scene.previous_card_positions.clear()
	scene._render()


func _assert_cancel_animation_started() -> void:
	if scene.returning_drag_preview == null:
		push_error("Drag cancel smoke failed: return animation did not start")
		quit(1)
	if scene.drag_preview != null:
		push_error("Drag cancel smoke failed: active drag preview was not handed to return animation")
		quit(1)
	if scene.selected.is_empty():
		push_error("Drag cancel smoke failed: selection cleared before return animation")
		quit(1)
	if not _preview_has_label(scene.returning_drag_preview, "苹果"):
		push_error("Drag cancel smoke failed: covered dragged card strip text missing")
		quit(1)


func _assert_cancel_animation_finished() -> void:
	if scene.returning_drag_preview != null:
		push_error("Drag cancel smoke failed: returning preview was not cleared")
		quit(1)
	if not scene.selected.is_empty():
		push_error("Drag cancel smoke failed: selection not cleared after return animation")
		quit(1)
	for card_id in source_positions.keys():
		var button := _find_visible_card_button(scene, int(card_id))
		if button == null:
			push_error("Drag cancel smoke failed: source card not restored")
			quit(1)
			return
		if button.position.distance_to(source_positions[card_id]) > 0.1:
			push_error("Drag cancel smoke failed: restored group shifted after cancel")
			quit(1)


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


func _preview_has_label(node: Node, text: String) -> bool:
	for child in node.get_children():
		if child is Label and child.text == text:
			return true
		if _preview_has_label(child, text):
			return true
	return false
