extends SceneTree

var scene: Node
var capture_mode := false
var frames := 0
var clicked := false


func _initialize() -> void:
	capture_mode = OS.get_cmdline_user_args().has("--capture")
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene._ready()


func _process(_delta: float) -> bool:
	frames += 1
	if capture_mode:
		if frames > 2:
			quit(0)
		return false

	if not clicked:
		var start_button := _find_start_button(scene)
		if start_button == null:
			push_error("Start menu smoke failed: start button not found")
			quit(1)
			return false
		if not scene.menu_active:
			push_error("Start menu smoke failed: menu did not start active")
			quit(1)
			return false
		if _count_buttons(scene) != 1:
			push_error("Start menu smoke failed: menu rendered gameplay buttons")
			quit(1)
			return false
		start_button.pressed.emit()
		_finish_round_transition(scene)
		clicked = true
		return false

	if scene.menu_active:
		push_error("Start menu smoke failed: menu did not close after start")
		quit(1)
		return false
	if _find_start_button(scene) != null:
		push_error("Start menu smoke failed: start button still rendered")
		quit(1)
		return false
	print("START_MENU_SMOKE_PASS")
	quit(0)
	return false


func _find_start_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and child.has_meta("start_button"):
			return child
		var nested := _find_start_button(child)
		if nested != null:
			return nested
	return null


func _count_buttons(node: Node) -> int:
	var count := 0
	for child in node.get_children():
		if child is Button:
			count += 1
		count += _count_buttons(child)
	return count


func _finish_round_transition(target: Node) -> void:
	if target.round_transition_active:
		target._finish_round_close_transition(target.round_transition_overlay)
	if target.round_transition_active:
		target._finish_round_open_transition(target.round_transition_overlay)
