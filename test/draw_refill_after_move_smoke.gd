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
	scene.deck.clear()
	scene.draw_stack = [
		scene._word("苹果", true),
		scene._word("香蕉", true),
		scene._word("葡萄", true),
		scene._word("桃子", true),
	]
	scene.previous_card_positions.clear()
	for i in range(1, 4):
		scene.previous_card_positions[scene.draw_stack[i]["id"]] = scene._draw_card_position_for_size(i, 4)
	scene._render()

	var refill_card_id: int = scene.draw_stack[0]["id"]
	scene.selected = scene._selection_for_draw(3)
	scene._remove_selected_from_source()
	if scene.draw_stack.size() != 3:
		push_error("Draw refill after move smoke failed: top draw card was not removed")
		quit(1)
		return false
	var refill_target: Vector2 = scene._draw_card_position_for_size(0, 3)
	var refill_start: Vector2 = scene.previous_card_positions.get(refill_card_id, Vector2.ZERO)
	if refill_start.distance_to(refill_target + Vector2(18.0, 0.0)) > 0.1:
		push_error("Draw refill after move smoke failed: hidden draw card did not get a leftward refill start")
		quit(1)
		return false

	scene._render()
	var refill_button := _find_card_button(scene, refill_card_id)
	if refill_button == null:
		push_error("Draw refill after move smoke failed: refill card was not rendered")
		quit(1)
		return false
	if refill_button.position.distance_to(refill_start) > 0.1:
		push_error("Draw refill after move smoke failed: refill card did not start from synthesized position")
		quit(1)
		return false

	print("DRAW_REFILL_AFTER_MOVE_SMOKE_PASS")
	quit(0)
	return false


func _find_card_button(node: Node, card_id: int) -> Button:
	for child in node.get_children():
		if child is Button and child.has_meta("card_id") and int(child.get_meta("card_id")) == card_id:
			return child
		var nested := _find_card_button(child, card_id)
		if nested != null:
			return nested
	return null
