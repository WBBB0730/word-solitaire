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

	scene.menu_active = false
	scene.active_categories.clear()
	scene.active_order.clear()
	scene._render()

	var slot := _find_empty_category_slot(scene)
	if slot == null:
		push_error("Category empty hint smoke failed: empty category slot not found")
		quit(1)
		return false
	if slot.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		push_error("Category empty hint smoke failed: empty category slot receives input")
		quit(1)
		return false
	if slot.text != "":
		push_error("Category empty hint smoke failed: empty category slot should not show a plus sign")
		quit(1)
		return false

	var normal_style := slot.get_theme_stylebox("normal")
	if not (normal_style is StyleBoxFlat):
		push_error("Category empty hint smoke failed: empty category slot style is not flat")
		quit(1)
		return false
	if normal_style.bg_color.a < 0.36 or normal_style.bg_color.a > 0.48 or normal_style.bg_color.b < 0.30 or normal_style.bg_color.b > 0.48:
		push_error("Category empty hint smoke failed: empty category slot fill is not balanced yellow")
		quit(1)
		return false
	if normal_style.border_width_left != 0 or normal_style.border_color.a > 0.01:
		push_error("Category empty hint smoke failed: empty category slot should not use a solid border")
		quit(1)
		return false
	if _count_category_slot_dashes(slot) < 12:
		push_error("Category empty hint smoke failed: dashed category outline not found")
		quit(1)
		return false
	if _find_category_empty_hint(slot) != null:
		push_error("Category empty hint smoke failed: extra yellow accent should not be rendered")
		quit(1)
		return false

	print("CATEGORY_EMPTY_HINT_SMOKE_PASS")
	quit(0)
	return false


func _find_empty_category_slot(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and child.has_meta("category_empty_slot"):
			return child
		var nested := _find_empty_category_slot(child)
		if nested != null:
			return nested
	return null


func _count_category_slot_dashes(node: Node) -> int:
	var count := 0
	for child in node.get_children():
		if child.has_meta("category_slot_dash"):
			count += 1
		count += _count_category_slot_dashes(child)
	return count


func _find_category_empty_hint(node: Node) -> Control:
	for child in node.get_children():
		if child is Control and child.has_meta("category_empty_hint"):
			return child
		var nested := _find_category_empty_hint(child)
		if nested != null:
			return nested
	return null
