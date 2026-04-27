extends SceneTree

var scene: Node
var initialized := false
var presses_sent := 0
var checked := false
var deck_button: Control
var press_position := Vector2.ZERO


func _initialize() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)


func _process(_delta: float) -> bool:
	if checked:
		return false
	if not initialized:
		initialized = true
		_setup_scene()

	if presses_sent < 5:
		_send_touch_with_emulated_mouse_pair()
		presses_sent += 1
		return false

	checked = true
	_check_results()
	quit(0)
	return false


func _setup_scene() -> void:
	scene._ready()
	scene.menu_active = false
	scene.deck.clear()
	for word in ["苹果", "香蕉", "葡萄", "桃子", "菠萝", "荔枝"]:
		scene.deck.append(scene._word(word, false))
	scene.draw_stack.clear()
	scene._render()

	deck_button = _find_deck_button(scene)
	if deck_button == null:
		push_error("Deck input burst smoke failed: deck button not found")
		quit(1)
		return
	press_position = deck_button.global_position + deck_button.size * 0.5


func _send_touch_with_emulated_mouse_pair() -> void:
	deck_button = _find_deck_button(scene)
	if deck_button == null:
		push_error("Deck input burst smoke failed: deck button disappeared before touch")
		quit(1)
		return
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = press_position
	deck_button.gui_input.emit(touch)
	scene._input(touch)

	deck_button = _find_deck_button(scene)
	if deck_button == null:
		push_error("Deck input burst smoke failed: deck button disappeared before emulated mouse")
		quit(1)
		return
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	mouse.position = press_position
	deck_button.gui_input.emit(mouse)
	scene._input(mouse)


func _check_results() -> void:
	if scene.draw_stack.size() != 5:
		push_error("Deck input burst smoke failed: rapid deck presses were dropped")
		quit(1)
		return
	if scene.deck.size() != 1:
		push_error("Deck input burst smoke failed: deck size did not match rapid presses")
		quit(1)
		return
	if scene.draw_flights.size() != 3:
		push_error("Deck input burst smoke failed: only the visible draw cards should stay animated")
		quit(1)
		return
	if scene.draw_animation_nodes.size() != 3:
		push_error("Deck input burst smoke failed: hidden draw cards still have animation nodes")
		quit(1)
		return
	for node in scene.draw_animation_nodes.values():
		if is_instance_valid(node) and node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			push_error("Deck input burst smoke failed: animated cards can block later presses")
			quit(1)
			return
	for raw_card_id in scene.draw_flights.keys():
		var card_id := int(raw_card_id)
		var stack_index: int = scene._draw_stack_index_for_card_id(card_id)
		if not scene._draw_stack_index_is_visible(stack_index):
			push_error("Deck input burst smoke failed: hidden draw card stayed animated")
			quit(1)
			return

	print("DECK_INPUT_BURST_SMOKE_PASS")


func _find_deck_button(node: Node) -> Control:
	for child in node.get_children():
		if child is Control and child.has_meta("deck_button"):
			return child
		var nested := _find_deck_button(child)
		if nested != null:
			return nested
	return null
