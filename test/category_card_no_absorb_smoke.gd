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
	_load_controlled_category_level()
	_drag_category_to_empty_slot()
	if scene.absorbing_drag_preview != null:
		push_error("Category card no absorb smoke failed: category card used absorb animation")
		quit(1)
		return false
	if not scene.active_categories.has("水果"):
		push_error("Category card no absorb smoke failed: category did not enter area 3")
		quit(1)
		return false
	if scene.steps_left != 119:
		push_error("Category card no absorb smoke failed: move did not consume exactly one step")
		quit(1)
		return false
	if not scene.selected.is_empty():
		push_error("Category card no absorb smoke failed: selection was not cleared")
		quit(1)
		return false
	print("CATEGORY_CARD_NO_ABSORB_SMOKE_PASS")
	quit(0)
	return false


func _load_controlled_category_level() -> void:
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
		[scene._category("水果")],
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
	scene.status_text = "category card no absorb test"
	scene.previous_card_positions.clear()
	scene._render()


func _drag_category_to_empty_slot() -> void:
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
	scene._update_drag(local_pos, source_center + Vector2(20, -80))
	scene._finish_drag(target_center)
