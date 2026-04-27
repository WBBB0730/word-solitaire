extends SceneTree

var scene: Node
var frames := 0
var starting_deck_size := 0
var clicked := false


func _initialize() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene._ready()
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
		deck_button.pressed.emit()
		clicked = true
		return false
	if scene.deck_animation_busy:
		scene._process(0.05)
	if frames < 24 and scene.deck_animation_busy:
		return false
	if scene.deck_animation_busy:
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
	print("DECK_CLICK_SMOKE_PASS")
	quit(0)
	return false


func _find_deck_button(root_node: Node) -> Button:
	for child in root_node.get_children():
		if child is Button and String(child.text).begins_with("牌堆"):
			return child
	return null
