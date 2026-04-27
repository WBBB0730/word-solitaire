extends SceneTree

var scene: Node
var checked := false
var capture_mode := false
var frames := 0


func _initialize() -> void:
	capture_mode = OS.get_cmdline_user_args().has("--capture")
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)


func _process(_delta: float) -> bool:
	if checked:
		if capture_mode:
			frames += 1
			if frames > 10:
				quit(0)
		return false
	checked = true
	scene._ready()
	scene.menu_active = false
	scene.deck.clear()
	scene.draw_stack = [
		scene._word("苹果", true),
		scene._word("香蕉", true),
		scene._word("葡萄", true),
	]
	scene.steps_left = 120
	scene._render()

	scene._handle_deck_pressed()
	if not scene.deck_animation_busy:
		push_error("Wash animation smoke failed: animation did not start")
		quit(1)
		return false
	if scene.wash_animation_nodes.size() != 3:
		push_error("Wash animation smoke failed: visible cards were not animated")
		quit(1)
		return false
	for node in scene.wash_animation_nodes:
		if is_instance_valid(node) and node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			push_error("Wash animation smoke failed: wash animation card blocks input")
			quit(1)
			return false
	if scene.deck.size() != 0 or scene.draw_stack.size() != 3:
		push_error("Wash animation smoke failed: cards moved before animation finished")
		quit(1)
		return false
	if scene.steps_left != 120:
		push_error("Wash animation smoke failed: step consumed before animation finished")
		quit(1)
		return false
	if capture_mode:
		return false

	var keeper: Control = scene.wash_animation_nodes[scene.wash_animation_nodes.size() - 1]
	if not is_instance_valid(keeper) or keeper.text != "葡萄":
		push_error("Wash animation smoke failed: top returning card changed before animation")
		quit(1)
		return false
	scene._process(scene.DRAW_ANIM_TIME * 0.28)
	if keeper.text != "":
		push_error("Wash animation smoke failed: returning card did not flip to back early enough")
		quit(1)
		return false
	for node in scene.wash_animation_nodes:
		if is_instance_valid(node) and node.text != "":
			push_error("Wash animation smoke failed: an under-card still shows face text after flip")
			quit(1)
			return false
	if scene.wash_animation_nodes.size() != 3:
		push_error("Wash animation smoke failed: wash animation collapsed before finishing")
		quit(1)
		return false
	if keeper.modulate.a < 0.99:
		push_error("Wash animation smoke failed: returning card fades before deck appears")
		quit(1)
		return false

	scene._process(scene.DRAW_ANIM_TIME)
	if scene.deck_animation_busy:
		push_error("Wash animation smoke failed: animation flag not cleared")
		quit(1)
		return false
	if scene.draw_stack.size() != 0 or scene.deck.size() != 3:
		push_error("Wash animation smoke failed: cards did not return to deck")
		quit(1)
		return false
	if scene.steps_left != 119:
		push_error("Wash animation smoke failed: step not consumed after animation")
		quit(1)
		return false
	for card in scene.deck:
		if bool(card["face_up"]):
			push_error("Wash animation smoke failed: washed card stayed face-up")
			quit(1)
			return false

	print("WASH_ANIMATION_SMOKE_PASS")
	quit(0)
	return false
