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
	scene.deck = [scene._word("苹果", false)]
	scene.draw_stack.clear()
	scene.previous_card_positions.clear()
	scene._render()

	scene._handle_deck_pressed()
	if scene.draw_stack.size() != 1:
		push_error("Draw flip sync smoke failed: card was not added to draw layout immediately")
		quit(1)
		return false
	var card_id: int = scene.draw_stack[0]["id"]
	if not scene.animating_draw_cards.has(card_id):
		push_error("Draw flip sync smoke failed: card is not hidden from static draw layout during animation")
		quit(1)
		return false
	var fly_card = scene.draw_animation_nodes.get(card_id)
	if fly_card == null:
		push_error("Draw flip sync smoke failed: animated card node not found")
		quit(1)
		return false
	if fly_card.text != "":
		push_error("Draw flip sync smoke failed: animated card did not start as a card back")
		quit(1)
		return false

	scene._process(scene.DRAW_ANIM_TIME * 0.42)
	if fly_card.text != "苹果":
		push_error("Draw flip sync smoke failed: animated card did not flip to face early enough")
		quit(1)
		return false

	scene._process(scene.DRAW_ANIM_TIME)
	if scene.deck_animation_busy:
		push_error("Draw flip sync smoke failed: animation did not finish")
		quit(1)
		return false
	if scene.animating_draw_cards.has(card_id):
		push_error("Draw flip sync smoke failed: animation hidden marker was not cleared")
		quit(1)
		return false
	if scene.draw_stack.size() != 1:
		push_error("Draw flip sync smoke failed: card was duplicated after animation")
		quit(1)
		return false

	print("DRAW_FLIP_SYNC_SMOKE_PASS")
	quit(0)
	return false
