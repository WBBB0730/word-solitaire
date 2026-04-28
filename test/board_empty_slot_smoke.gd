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
			if frames > 2:
				quit(0)
		return false
	checked = true

	scene.menu_active = false
	scene.columns = [[], [], [], []]
	scene._render()

	var slots := _find_board_empty_slots(scene)
	if slots.size() != scene.BOARD_COLUMN_COUNT:
		push_error("Board empty slot smoke failed: expected 4 empty slots, got " + str(slots.size()))
		quit(1)
		return false
	for slot in slots:
		if slot.text != "":
			push_error("Board empty slot smoke failed: empty board slot should not show a plus sign")
			quit(1)
			return false
		if slot.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			push_error("Board empty slot smoke failed: empty board slot should not receive input")
			quit(1)
			return false
		var normal_style: StyleBox = slot.get_theme_stylebox("normal")
		if not (normal_style is StyleBoxFlat):
			push_error("Board empty slot smoke failed: empty board slot style is not flat")
			quit(1)
			return false
		var flat_style := normal_style as StyleBoxFlat
		if flat_style.border_width_left != 0 or flat_style.border_color.a > 0.01:
			push_error("Board empty slot smoke failed: empty board slot still uses a solid border")
			quit(1)
			return false
		if _count_board_slot_dashes(slot) < 12:
			push_error("Board empty slot smoke failed: dashed board outline not found")
			quit(1)
			return false

	if not capture_mode:
		print("BOARD_EMPTY_SLOT_SMOKE_PASS")
		quit(0)
	return false


func _find_board_empty_slots(node: Node) -> Array:
	var slots := []
	for child in node.get_children():
		if child is Button and child.has_meta("board_empty_slot"):
			slots.append(child)
		slots.append_array(_find_board_empty_slots(child))
	return slots


func _count_board_slot_dashes(node: Node) -> int:
	var count := 0
	for child in node.get_children():
		if child.has_meta("board_slot_dash"):
			count += 1
		count += _count_board_slot_dashes(child)
	return count
