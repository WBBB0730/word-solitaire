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

	var start_button := _find_button_with_meta(scene, "start_button")
	if start_button == null:
		push_error("Button click sfx scope failed: start button not found")
		quit(1)
		return false
	if not _has_button_down_connection(start_button):
		push_error("Button click sfx scope failed: start button has no click feedback connection")
		quit(1)
		return false

	start_button.pressed.emit()
	_finish_round_transition(scene)
	var restart_button := _find_button_with_meta(scene, "restart_button")
	var home_button := _find_button_with_meta(scene, "home_button")
	if restart_button == null or home_button == null:
		push_error("Button click sfx scope failed: top buttons not found")
		quit(1)
		return false
	if not _has_button_down_connection(restart_button) or not _has_button_down_connection(home_button):
		push_error("Button click sfx scope failed: top buttons have no click feedback connection")
		quit(1)
		return false

	var card_button := _find_card_button(scene)
	if card_button == null:
		push_error("Button click sfx scope failed: card button not found")
		quit(1)
		return false
	if _has_button_down_connection(card_button):
		push_error("Button click sfx scope failed: card button is wired as a UI button")
		quit(1)
		return false

	var deck_control := _find_control_with_meta(scene, "deck_button")
	if deck_control == null:
		push_error("Button click sfx scope failed: deck control not found")
		quit(1)
		return false
	if deck_control is Button:
		push_error("Button click sfx scope failed: deck area is a Button")
		quit(1)
		return false

	print("BUTTON_CLICK_SFX_SCOPE_SMOKE_PASS")
	quit(0)
	return false


func _finish_round_transition(target: Node) -> void:
	if target.round_transition_active:
		target._finish_round_close_transition(target.round_transition_overlay)
	if target.round_transition_active:
		target._finish_round_open_transition(target.round_transition_overlay)


func _has_button_down_connection(button: Button) -> bool:
	for connection in button.button_down.get_connections():
		if String(connection["callable"].get_method()) == "_on_button_feedback_down":
			return true
	return false


func _find_button_with_meta(node: Node, meta_name: String) -> Button:
	for child in node.get_children():
		if child is Button and child.has_meta(meta_name):
			return child
		var nested := _find_button_with_meta(child, meta_name)
		if nested != null:
			return nested
	return null


func _find_card_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and child.has_meta("card_id"):
			return child
		var nested := _find_card_button(child)
		if nested != null:
			return nested
	return null


func _find_control_with_meta(node: Node, meta_name: String) -> Control:
	for child in node.get_children():
		if child is Control and child.has_meta(meta_name):
			return child
		var nested := _find_control_with_meta(child, meta_name)
		if nested != null:
			return nested
	return null
