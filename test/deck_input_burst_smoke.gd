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
	for word in ["苹果", "香蕉", "葡萄", "桃子", "菠萝", "荔枝"]:
		scene.deck.append(scene._word(word, false))
	scene.draw_stack.clear()
	scene._render()

	var press_position: Vector2 = scene._deck_rect().get_center()
	for i in range(5):
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		event.position = press_position
		scene._input(event)

	if scene.draw_stack.size() != 5:
		push_error("Deck input burst smoke failed: rapid deck presses were dropped")
		quit(1)
		return false
	if scene.deck.size() != 1:
		push_error("Deck input burst smoke failed: deck size did not match rapid presses")
		quit(1)
		return false
	if scene.draw_flights.size() != 3:
		push_error("Deck input burst smoke failed: only the visible draw cards should stay animated")
		quit(1)
		return false
	if scene.draw_animation_nodes.size() != 3:
		push_error("Deck input burst smoke failed: hidden draw cards still have animation nodes")
		quit(1)
		return false
	for node in scene.draw_animation_nodes.values():
		if is_instance_valid(node) and node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			push_error("Deck input burst smoke failed: animated cards can block later presses")
			quit(1)
			return false
	for raw_card_id in scene.draw_flights.keys():
		var card_id := int(raw_card_id)
		var stack_index: int = scene._draw_stack_index_for_card_id(card_id)
		if not scene._draw_stack_index_is_visible(stack_index):
			push_error("Deck input burst smoke failed: hidden draw card stayed animated")
			quit(1)
			return false

	print("DECK_INPUT_BURST_SMOKE_PASS")
	quit(0)
	return false
