extends SceneTree

var scene: Node
var capture_mode := false
var frames := 0
var drag_started := false


func _initialize() -> void:
	capture_mode = OS.get_cmdline_user_args().has("--capture")
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene._ready()
	scene.menu_active = false
	scene._render()


func _process(_delta: float) -> bool:
	frames += 1
	if not drag_started:
		_start_board_drag()
		_assert_direct_drag_state()
		drag_started = true
		if not capture_mode:
			print("DRAG_DIRECT_SMOKE_PASS")
			quit(0)
		return false
	if capture_mode and frames > 8:
		quit(0)
	return false


func _start_board_drag() -> void:
	var col_idx := 0
	var card_idx: int = scene.columns[col_idx].size() - 1
	var selection: Dictionary = scene._selection_for_board(col_idx, card_idx)
	var source_pos := Vector2(
		scene._column_x(col_idx) + scene.CARD_W * 0.5,
		scene.BOARD_Y + card_idx * scene.STACK_STEP + scene.CARD_H * 0.5
	)
	var local_pos := Vector2(scene.CARD_W * 0.5, scene.CARD_H * 0.5)
	scene._begin_drag_candidate(selection, local_pos, source_pos)
	scene._update_drag(local_pos, source_pos + Vector2(48, -76))


func _assert_direct_drag_state() -> void:
	var cards: Array = scene.selected.get("cards", [])
	if cards.is_empty():
		push_error("Direct drag smoke failed: no selected card")
		quit(1)
		return
	var card_id: int = cards[0]["id"]
	var state := {
		"found_source": false,
		"visible_source": false,
		"found_drag_card": false,
	}
	_scan_card_controls(scene, card_id, state)
	if not state["found_source"]:
		push_error("Direct drag smoke failed: source card control not found")
		quit(1)
		return
	if state["visible_source"]:
		push_error("Direct drag smoke failed: source card remains visible")
		quit(1)
		return
	if not state["found_drag_card"]:
		push_error("Direct drag smoke failed: opaque dragged card not found")
		quit(1)


func _scan_card_controls(node: Node, card_id: int, state: Dictionary) -> void:
	for child in node.get_children():
		if child is Control and child.has_meta("card_id") and child.get_meta("card_id") == card_id:
			if _is_descendant_of(child, scene.drag_preview):
				if child.visible and child.modulate.a >= 0.99:
					state["found_drag_card"] = true
			else:
				state["found_source"] = true
				if child.visible:
					state["visible_source"] = true
		_scan_card_controls(child, card_id, state)


func _is_descendant_of(node: Node, ancestor: Node) -> bool:
	var current := node
	while current != null:
		if current == ancestor:
			return true
		current = current.get_parent()
	return false
