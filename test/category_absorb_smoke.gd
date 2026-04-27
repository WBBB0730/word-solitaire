extends SceneTree

var scene: Node
var capture_mode := false
var frames := 0
var started := false


func _initialize() -> void:
	capture_mode = OS.get_cmdline_user_args().has("--capture")
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene._ready()


func _process(_delta: float) -> bool:
	frames += 1
	if not started:
		started = true
		_load_controlled_absorb_level()
		_start_absorb_drag()
		_assert_absorb_animation_started()
		if not capture_mode:
			scene._finish_category_absorb_animation()
			scene._finish_category_absorb_pulse()
			_assert_absorb_animation_finished()
			print("CATEGORY_ABSORB_SMOKE_PASS")
			quit(0)
		return false
	if capture_mode and frames > 20:
		quit(0)
	return false


func _load_controlled_absorb_level() -> void:
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
		[],
		[],
		[],
	]
	scene.active_categories.clear()
	scene.active_order.clear()
	scene.active_categories["水果"] = {"collected": []}
	scene.active_order.append("水果")
	scene.selected.clear()
	scene.steps_left = 120
	scene.game_over = false
	scene.status_text = "category absorb test"
	scene.previous_card_positions.clear()
	scene._render()


func _start_absorb_drag() -> void:
	var source_center := Vector2(
		scene._column_x(0) + scene.CARD_W * 0.5,
		scene.BOARD_Y + scene.CARD_H * 0.5
	)
	var target_center := Vector2(
		scene._column_x(0) + scene.CARD_W * 0.5,
		scene.CATEGORY_Y + scene.CARD_H * 0.5
	)
	var local_pos := Vector2(scene.CARD_W * 0.5, scene.CARD_H * 0.5)
	scene._begin_drag_candidate(scene._selection_for_board(0, 0), local_pos, source_center)
	scene._update_drag(local_pos, source_center + Vector2(30, -80))
	scene._finish_drag(target_center)


func _assert_absorb_animation_started() -> void:
	if scene.absorbing_drag_preview == null:
		push_error("Category absorb smoke failed: absorb animation did not start")
		quit(1)
	if scene.drag_preview != null:
		push_error("Category absorb smoke failed: drag preview was not handed to absorb animation")
		quit(1)
	if scene.selected.is_empty():
		push_error("Category absorb smoke failed: selection cleared before absorb animation")
		quit(1)
	if scene.steps_left != 120:
		push_error("Category absorb smoke failed: step consumed before animation finished")
		quit(1)
	if not scene.active_categories["水果"]["collected"].has("苹果"):
		push_error("Category absorb smoke failed: word was not collected")
		quit(1)


func _assert_absorb_animation_finished() -> void:
	if scene.absorbing_drag_preview != null:
		push_error("Category absorb smoke failed: absorbing preview was not cleared")
		quit(1)
	if not scene.selected.is_empty():
		push_error("Category absorb smoke failed: selection not cleared after animation")
		quit(1)
	if scene.steps_left != 119:
		push_error("Category absorb smoke failed: step not consumed after animation")
		quit(1)
