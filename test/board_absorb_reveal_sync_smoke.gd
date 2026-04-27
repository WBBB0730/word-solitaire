extends SceneTree

var scene: Node
var hidden_card_id := 0
var checked := false


func _initialize() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)


func _process(_delta: float) -> bool:
	if checked:
		return false
	checked = true
	scene._ready()
	_load_controlled_level()
	_start_absorb_drag()
	_assert_reveal_and_absorb_started_together()
	print("BOARD_ABSORB_REVEAL_SYNC_SMOKE_PASS")
	quit(0)
	return false


func _load_controlled_level() -> void:
	scene.categories = {
		"水果": ["苹果", "香蕉"],
		"家具": ["桌子", "椅子"],
	}
	scene.next_card_id = 1
	scene.word_to_category.clear()
	for word in scene.categories["水果"]:
		scene.word_to_category[word] = "水果"
	for word in scene.categories["家具"]:
		scene.word_to_category[word] = "家具"

	var hidden_card: Dictionary = scene._word("桌子", false)
	var moving_card: Dictionary = scene._word("苹果", true)
	hidden_card_id = int(hidden_card["id"])
	scene.deck.clear()
	scene.draw_stack.clear()
	scene.columns = [
		[hidden_card, moving_card],
		[],
		[],
		[],
	]
	scene.active_categories.clear()
	scene.active_order.clear()
	scene.active_categories["水果"] = {"collected": []}
	scene.active_order.append("水果")
	scene.selected.clear()
	scene.menu_active = false
	scene.steps_left = 120
	scene.game_over = false
	scene.previous_card_positions.clear()
	scene.revealing_board_cards.clear()
	scene._render()


func _start_absorb_drag() -> void:
	var source_center := Vector2(
		scene._column_x(0) + scene.CARD_W * 0.5,
		scene.BOARD_Y + scene.STACK_STEP + scene.CARD_H * 0.5
	)
	var target_center := Vector2(
		scene._column_x(0) + scene.CARD_W * 0.5,
		scene.CATEGORY_Y + scene.CARD_H * 0.5
	)
	var local_pos := Vector2(scene.CARD_W * 0.5, scene.CARD_H * 0.5)
	scene._begin_drag_candidate(scene._selection_for_board(0, 1), local_pos, source_center)
	scene._update_drag(local_pos, source_center + Vector2(24, -80))
	scene._finish_drag(target_center)


func _assert_reveal_and_absorb_started_together() -> void:
	if scene.absorbing_drag_preview == null:
		push_error("Board absorb reveal sync failed: absorb animation did not start")
		quit(1)
		return
	var hidden_button := _find_card_button(scene, hidden_card_id)
	if hidden_button == null:
		push_error("Board absorb reveal sync failed: newly exposed card button was not rendered")
		quit(1)
		return
	var face_overlay := _find_face_overlay(scene, hidden_card_id, hidden_button)
	var is_revealing_back := hidden_button.text == "" and hidden_button.disabled and hidden_button.mouse_filter == Control.MOUSE_FILTER_IGNORE
	if not is_revealing_back or face_overlay == null:
		push_error("Board absorb reveal sync failed: newly exposed card did not start flip while absorb was active")
		quit(1)
		return
	if scene.steps_left != 120:
		push_error("Board absorb reveal sync failed: step was consumed before absorb finished")
		quit(1)
		return


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
