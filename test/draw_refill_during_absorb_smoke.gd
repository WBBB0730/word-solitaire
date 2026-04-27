extends SceneTree

var scene: Node
var checked := false


func _initialize() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)


func _process(_delta: float) -> bool:
	if checked:
		return false
	checked = true
	scene._ready()
	scene.menu_active = false
	scene.categories = {"水果": ["苹果", "香蕉", "橙子", "葡萄"]}
	scene.word_to_category.clear()
	for word in scene.categories["水果"]:
		scene.word_to_category[word] = "水果"
	scene.next_card_id = 1
	scene.deck.clear()
	scene.draw_stack = [
		scene._word("苹果", true),
		scene._word("香蕉", true),
		scene._word("橙子", true),
		scene._word("葡萄", true),
	]
	scene.columns = [[], [], [], []]
	scene.active_categories.clear()
	scene.active_categories["水果"] = {"collected": []}
	scene.active_order.clear()
	scene.active_order.append("水果")
	scene.steps_left = scene.STARTING_STEPS
	scene.previous_card_positions.clear()
	scene._render()

	var refill_card_id: int = scene.draw_stack[0]["id"]
	var source_center: Vector2 = scene._draw_card_position(3) + Vector2(scene.CARD_W, scene.CARD_H) * 0.5
	var target_center: Vector2 = Vector2(scene._column_x(0), scene.CATEGORY_Y) + Vector2(scene.CARD_W, scene.CARD_H) * 0.5
	var local_pos := Vector2(scene.CARD_W, scene.CARD_H) * 0.5
	scene._begin_drag_candidate(scene._selection_for_draw(3), local_pos, source_center)
	scene._update_drag(local_pos, source_center + Vector2(-10, 90))
	scene._finish_drag(target_center)

	if scene.absorbing_drag_preview == null:
		push_error("Draw refill during absorb smoke failed: absorb animation did not start")
		quit(1)
		return false
	if scene.draw_stack.size() != 3:
		push_error("Draw refill during absorb smoke failed: draw top card was not removed")
		quit(1)
		return false
	var refill_button := _find_draw_card_button(scene, refill_card_id)
	if refill_button == null:
		push_error("Draw refill during absorb smoke failed: refill card was not rendered during absorb")
		quit(1)
		return false
	var expected_start: Vector2 = scene._draw_card_position_for_size(0, 3) + Vector2(18.0, 0.0)
	if refill_button.position.distance_to(expected_start) > 0.1:
		push_error("Draw refill during absorb smoke failed: refill card did not start while absorb is running")
		quit(1)
		return false
	if scene.steps_left != scene.STARTING_STEPS:
		push_error("Draw refill during absorb smoke failed: move step was consumed before absorb finished")
		quit(1)
		return false

	print("DRAW_REFILL_DURING_ABSORB_SMOKE_PASS")
	quit(0)
	return false


func _find_draw_card_button(node: Node, card_id: int) -> Button:
	for child in node.get_children():
		if child is Button and child.has_meta("draw_card_button") and child.has_meta("card_id") and int(child.get_meta("card_id")) == card_id:
			return child
		var nested := _find_draw_card_button(child, card_id)
		if nested != null:
			return nested
	return null
