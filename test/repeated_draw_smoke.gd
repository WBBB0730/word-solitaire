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
	scene.deck = [
		scene._word("苹果", false),
		scene._word("香蕉", false),
		scene._word("葡萄", false),
	]
	scene.draw_stack.clear()
	scene.previous_card_positions.clear()
	scene._render()

	scene._handle_deck_pressed()
	if scene.deck_animation_busy:
		push_error("Repeated draw smoke failed: draw animation locked the deck")
		quit(1)
		return false
	if scene.draw_stack.size() != 1 or scene.draw_flights.size() != 1:
		push_error("Repeated draw smoke failed: first draw did not start correctly")
		quit(1)
		return false
	var first_card_id: int = scene.draw_stack[0]["id"]
	var first_node = scene.draw_animation_nodes.get(first_card_id)
	if not is_instance_valid(first_node):
		push_error("Repeated draw smoke failed: first animated card was not created")
		quit(1)
		return false
	if first_node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		push_error("Repeated draw smoke failed: animated draw card blocks deck input")
		quit(1)
		return false

	scene._handle_deck_pressed()
	if scene.draw_stack.size() != 2 or scene.deck.size() != 1:
		push_error("Repeated draw smoke failed: second draw was not accepted during first animation")
		quit(1)
		return false
	if scene.draw_flights.size() != 2:
		push_error("Repeated draw smoke failed: both draw animations are not active")
		quit(1)
		return false
	if not is_instance_valid(first_node):
		push_error("Repeated draw smoke failed: rerender removed the first animated card")
		quit(1)
		return false
	for node in scene.draw_animation_nodes.values():
		if is_instance_valid(node) and node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			push_error("Repeated draw smoke failed: an animated draw card blocks input")
			quit(1)
			return false
	var first_target: Vector2 = scene.draw_flights[first_card_id]["target"]
	if first_target.distance_to(scene._draw_card_position(0)) > 0.1:
		push_error("Repeated draw smoke failed: first animated card was not retargeted")
		quit(1)
		return false

	for i in range(10):
		scene._process(scene.DRAW_ANIM_TIME * 0.25)
	if not scene.draw_flights.is_empty():
		push_error("Repeated draw smoke failed: draw animations did not finish")
		quit(1)
		return false
	if not scene.animating_draw_cards.is_empty():
		push_error("Repeated draw smoke failed: hidden draw markers were not cleared")
		quit(1)
		return false
	if scene.draw_stack.size() != 2:
		push_error("Repeated draw smoke failed: finished animations duplicated or lost cards")
		quit(1)
		return false

	print("REPEATED_DRAW_SMOKE_PASS")
	quit(0)
	return false
