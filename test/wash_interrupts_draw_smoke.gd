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
	for word in ["苹果", "香蕉", "葡萄"]:
		scene.deck.append(scene._word(word, false))
	scene.draw_stack.clear()
	scene._render()

	for i in range(3):
		scene._handle_deck_pressed()
	if scene.draw_flights.is_empty():
		push_error("Wash interrupts draw smoke failed: draw animations did not start")
		quit(1)
		return false

	scene._handle_deck_pressed()
	if not scene.deck_animation_busy:
		push_error("Wash interrupts draw smoke failed: wash did not start")
		quit(1)
		return false
	if not scene.draw_flights.is_empty() or not scene.draw_animation_nodes.is_empty() or not scene.animating_draw_cards.is_empty():
		push_error("Wash interrupts draw smoke failed: draw animations survived into wash")
		quit(1)
		return false
	if scene.wash_animation_nodes.size() != 3:
		push_error("Wash interrupts draw smoke failed: wash did not take over visible cards")
		quit(1)
		return false

	scene._process(scene.DRAW_ANIM_TIME * 0.5)
	if not scene.draw_flights.is_empty() or not scene.draw_animation_nodes.is_empty():
		push_error("Wash interrupts draw smoke failed: draw animations reappeared during wash")
		quit(1)
		return false

	print("WASH_INTERRUPTS_DRAW_SMOKE_PASS")
	quit(0)
	return false
