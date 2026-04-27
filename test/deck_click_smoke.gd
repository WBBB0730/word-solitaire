extends SceneTree

var scene: Node
var frames := 0
var starting_deck_size := 0
var clicked := false


func _initialize() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene._ready()
	scene.menu_active = false
	scene._render()
	starting_deck_size = scene.deck.size()


func _process(_delta: float) -> bool:
	frames += 1
	if not clicked:
		var deck_button := _find_deck_button(scene)
		if deck_button == null:
			if frames > 3:
				push_error("Deck click smoke failed: deck button not found")
				quit(1)
			return false
		starting_deck_size = scene.deck.size()
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		deck_button.gui_input.emit(event)
		clicked = true
		return false
	if not scene.draw_flights.is_empty():
		scene._process(0.05)
	if frames < 24 and not scene.draw_flights.is_empty():
		return false
	if not scene.draw_flights.is_empty():
		push_error("Deck click smoke failed: draw animation did not finish")
		quit(1)
		return false
	if scene.draw_stack.size() != 1:
		push_error("Deck click smoke failed: draw stack did not receive a card")
		quit(1)
		return false
	if scene.deck.size() != starting_deck_size - 1:
		push_error("Deck click smoke failed: deck size did not decrease")
		quit(1)
		return false
	var deck_button := _find_deck_button(scene)
	if deck_button == null:
		push_error("Deck click smoke failed: deck button disappeared")
		quit(1)
		return false
	if deck_button.scale.distance_to(Vector2.ONE) > 0.01:
		push_error("Deck click smoke failed: deck button still has click bump animation")
		quit(1)
		return false
	print("DECK_CLICK_SMOKE_PASS")
	quit(0)
	return false


func _find_deck_button(root_node: Node) -> Control:
	for child in root_node.get_children():
		if child is Control and child.has_meta("deck_button"):
			return child
		var nested := _find_deck_button(child)
		if nested != null:
			return nested
	return null
