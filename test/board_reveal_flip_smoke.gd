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
	var card: Dictionary = scene._word("苹果", false)
	scene.deck.clear()
	scene.draw_stack.clear()
	scene.active_categories.clear()
	scene.active_order.clear()
	scene.columns.clear()
	scene.columns.append([card])
	scene.columns.append([])
	scene.columns.append([])
	scene.columns.append([])

	scene._reveal_bottom_card(0)
	scene._render()
	var btn := _find_card_button(scene, int(card["id"]))
	if btn == null:
		push_error("Board reveal flip smoke failed: revealed card button not found")
		quit(1)
		return false
	if not scene.revealing_board_cards.has(card["id"]):
		push_error("Board reveal flip smoke failed: revealed card was not marked for animation")
		quit(1)
		return false
	if btn.text != "" or not btn.disabled or btn.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		push_error("Board reveal flip smoke failed: revealed card did not start as inactive back")
		quit(1)
		return false
	var face_btn := _find_face_overlay(scene, int(card["id"]), btn)
	if face_btn == null:
		push_error("Board reveal flip smoke failed: synchronized face overlay was not created")
		quit(1)
		return false
	if face_btn.text != "苹果" or abs(face_btn.scale.x - 0.08) > 0.001 or face_btn.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		push_error("Board reveal flip smoke failed: face overlay did not start ready to open")
		quit(1)
		return false

	scene._finish_board_reveal_animation(int(card["id"]), btn, face_btn, card, "苹果", true)
	if scene.revealing_board_cards.has(card["id"]):
		push_error("Board reveal flip smoke failed: reveal marker was not cleared")
		quit(1)
		return false
	if btn.disabled or btn.mouse_filter != Control.MOUSE_FILTER_STOP:
		push_error("Board reveal flip smoke failed: revealed card did not become playable")
		quit(1)
		return false

	print("BOARD_REVEAL_FLIP_SMOKE_PASS")
	quit(0)
	return false


func _find_face_overlay(node: Node, card_id: int, original: Button) -> Button:
	for child in node.get_children():
		if child != original and child is Button and child.has_meta("card_id") and int(child.get_meta("card_id")) == card_id:
			return child
		var nested := _find_face_overlay(child, card_id, original)
		if nested != null:
			return nested
	return null


func _find_card_button(node: Node, card_id: int) -> Button:
	for child in node.get_children():
		if child is Button and child.has_meta("card_id") and int(child.get_meta("card_id")) == card_id:
			return child
		var nested := _find_card_button(child, card_id)
		if nested != null:
			return nested
	return null
