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

	var start := _find_button_with_meta(scene, "start_button")
	if start == null:
		push_error("Round transition smoke failed: start button not found")
		quit(1)
		return false
	start.pressed.emit()
	if not scene.round_transition_active:
		push_error("Round transition smoke failed: start did not begin close transition")
		quit(1)
		return false
	var top := _find_transition_panel(scene, "round_transition_top")
	var bottom := _find_transition_panel(scene, "round_transition_bottom")
	if top == null or bottom == null:
		push_error("Round transition smoke failed: transition panels were not created")
		quit(1)
		return false
	if top.color == scene.bg_color or bottom.color == scene.bg_color:
		push_error("Round transition smoke failed: curtain color matches the background")
		quit(1)
		return false
	if _find_transition_panel(scene, "round_transition_top_shadow") == null or _find_transition_panel(scene, "round_transition_bottom_shadow") == null:
		push_error("Round transition smoke failed: transition shadows were not created")
		quit(1)
		return false
	if not scene.menu_active:
		push_error("Round transition smoke failed: round changed before the curtain closed")
		quit(1)
		return false

	scene._finish_round_close_transition(scene.round_transition_overlay)
	if scene.menu_active:
		push_error("Round transition smoke failed: round did not start after curtain closed")
		quit(1)
		return false
	if not scene.round_transition_active:
		push_error("Round transition smoke failed: open transition did not continue after close")
		quit(1)
		return false
	scene._finish_round_open_transition(scene.round_transition_overlay)
	if scene.round_transition_active:
		push_error("Round transition smoke failed: transition did not finish cleanly")
		quit(1)
		return false

	for i in range(1, 90):
		scene.previous_card_positions[i] = Vector2(-999.0, -999.0)
	scene._on_restart_pressed()
	if not scene.round_transition_active:
		push_error("Round transition smoke failed: restart did not begin close transition")
		quit(1)
		return false
	scene._finish_round_close_transition(scene.round_transition_overlay)
	for card_button in _find_card_buttons(scene):
		if card_button.position.x < -100.0 or card_button.position.y < -100.0:
			push_error("Round transition smoke failed: restart cards reused stale positions")
			quit(1)
			return false

	print("ROUND_TRANSITION_SMOKE_PASS")
	quit(0)
	return false


func _find_button_with_meta(node: Node, meta_name: String) -> Button:
	for child in node.get_children():
		if child is Button and child.has_meta(meta_name):
			return child
		var nested := _find_button_with_meta(child, meta_name)
		if nested != null:
			return nested
	return null


func _find_transition_panel(node: Node, meta_name: String) -> ColorRect:
	for child in node.get_children():
		if child is ColorRect and child.has_meta(meta_name):
			return child
		var nested := _find_transition_panel(child, meta_name)
		if nested != null:
			return nested
	return null


func _find_card_buttons(node: Node) -> Array[Button]:
	var buttons: Array[Button] = []
	for child in node.get_children():
		if child is Button and child.has_meta("card_id"):
			buttons.append(child)
		buttons.append_array(_find_card_buttons(child))
	return buttons
