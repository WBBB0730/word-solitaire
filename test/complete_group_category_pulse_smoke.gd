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
	_load_complete_group_level()
	_drag_complete_group_to_empty_slot()
	_assert_completion_pulse_started()
	scene._finish_completed_category_pulse()
	_assert_completion_disappear_started()
	scene._finish_completed_category_disappear()
	_assert_completion_pulse_finished()
	print("COMPLETE_GROUP_CATEGORY_PULSE_SMOKE_PASS")
	quit(0)
	return false


func _load_complete_group_level() -> void:
	scene.categories = {
		"水果": ["苹果", "香蕉"],
	}
	scene.next_card_id = 1
	scene.word_to_category.clear()
	for word in scene.categories["水果"]:
		scene.word_to_category[word] = "水果"
	scene.deck.clear()
	scene.draw_stack.clear()
	scene.columns = [
		[scene._word("苹果"), scene._word("香蕉"), scene._category("水果")],
		[],
		[],
		[],
	]
	scene.active_categories.clear()
	scene.active_order.clear()
	scene.selected.clear()
	scene.menu_active = false
	scene.steps_left = 120
	scene.game_over = false
	scene.status_text = "complete group pulse test"
	scene.previous_card_positions.clear()
	scene._render()


func _drag_complete_group_to_empty_slot() -> void:
	var source_center := Vector2(
		scene._column_x(0) + scene.CARD_W * 0.5,
		scene.BOARD_Y + 2.0 * scene.STACK_STEP + scene.CARD_H * 0.5
	)
	var target_center := Vector2(
		scene._column_x(0) + scene.CARD_W * 0.5,
		scene.CATEGORY_Y + scene.CARD_H * 0.5
	)
	var local_pos := Vector2(scene.CARD_W * 0.5, scene.CARD_H * 0.5)
	scene._begin_drag_candidate(scene._selection_for_board(0, 2), local_pos, source_center)
	scene._update_drag(local_pos, source_center + Vector2(20, -96))
	scene._finish_drag(target_center)


func _assert_completion_pulse_started() -> void:
	if scene.completing_category_name != "水果":
		push_error("Complete group category pulse smoke failed: completion pulse did not start")
		quit(1)
	if not scene.active_categories.has("水果"):
		push_error("Complete group category pulse smoke failed: completed category disappeared before pulse")
		quit(1)
	if scene.active_categories["水果"]["collected"].size() != 2:
		push_error("Complete group category pulse smoke failed: collected count is not full during pulse")
		quit(1)
	if scene.steps_left != 120:
		push_error("Complete group category pulse smoke failed: step consumed before pulse finished")
		quit(1)
	if scene.selected.is_empty():
		push_error("Complete group category pulse smoke failed: selection cleared before pulse finished")
		quit(1)


func _assert_completion_disappear_started() -> void:
	if scene.completing_category_name != "水果":
		push_error("Complete group category pulse smoke failed: completion state cleared before disappear animation")
		quit(1)
	if not scene.active_categories.has("水果"):
		push_error("Complete group category pulse smoke failed: category disappeared before disappear animation")
		quit(1)
	if scene.steps_left != 120:
		push_error("Complete group category pulse smoke failed: step consumed before disappear animation")
		quit(1)


func _assert_completion_pulse_finished() -> void:
	if scene.active_categories.has("水果"):
		push_error("Complete group category pulse smoke failed: category did not disappear after pulse")
		quit(1)
	if scene.completing_category_name != "":
		push_error("Complete group category pulse smoke failed: completion state was not cleared")
		quit(1)
	if not scene.selected.is_empty():
		push_error("Complete group category pulse smoke failed: selection not cleared after pulse")
		quit(1)
	if scene.steps_left != 119:
		push_error("Complete group category pulse smoke failed: step not consumed after pulse")
		quit(1)
