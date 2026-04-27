extends SceneTree

var scene: Node
var checked := false


func _initialize() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene._ready()


func _process(_delta: float) -> bool:
	if checked:
		return false
	checked = true

	var start := _find_button_with_meta(scene, "start_button")
	if start == null:
		push_error("Top controls smoke failed: start button not found")
		quit(1)
		return false
	start.pressed.emit()
	_finish_round_transition(scene)

	var restart := _find_button_with_meta(scene, "restart_button")
	var home := _find_button_with_meta(scene, "home_button")
	if restart == null:
		push_error("Top controls smoke failed: restart button not found after start")
		quit(1)
		return false
	if home == null:
		push_error("Top controls smoke failed: home button not found after start")
		quit(1)
		return false
	if _find_label(scene, "第1关") != null:
		push_error("Top controls smoke failed: level label is still visible")
		quit(1)
		return false

	home.pressed.emit()
	if not scene.menu_active:
		push_error("Top controls smoke failed: home did not return to menu")
		quit(1)
		return false
	if _count_buttons(scene) != 1 or _find_button_with_meta(scene, "start_button") == null:
		push_error("Top controls smoke failed: home page is not isolated")
		quit(1)
		return false

	print("TOP_CONTROLS_SMOKE_PASS")
	quit(0)
	return false


func _find_button_with_meta(node: Node, meta_name: String) -> Button:
	for child in node.get_children():
		if _has_queued_ancestor(child):
			continue
		if child is Button and child.has_meta(meta_name):
			return child
		var nested := _find_button_with_meta(child, meta_name)
		if nested != null:
			return nested
	return null


func _find_label(node: Node, text: String) -> Label:
	for child in node.get_children():
		if _has_queued_ancestor(child):
			continue
		if child is Label and child.text == text:
			return child
		var nested := _find_label(child, text)
		if nested != null:
			return nested
	return null


func _count_buttons(node: Node) -> int:
	var count := 0
	for child in node.get_children():
		if _has_queued_ancestor(child):
			continue
		if child is Button:
			count += 1
		count += _count_buttons(child)
	return count


func _has_queued_ancestor(node: Node) -> bool:
	var current := node
	while current != null:
		if current.is_queued_for_deletion():
			return true
		current = current.get_parent()
	return false


func _finish_round_transition(target: Node) -> void:
	if target.round_transition_active:
		target._finish_round_close_transition(target.round_transition_overlay)
	if target.round_transition_active:
		target._finish_round_open_transition(target.round_transition_overlay)
