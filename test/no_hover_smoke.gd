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
	scene.categories = {"水果": ["苹果", "香蕉", "葡萄"]}
	scene.deck.clear()
	scene.draw_stack.clear()
	scene.columns = [[], [], [], []]
	scene.active_categories.clear()
	scene.active_order.clear()
	scene.active_categories["水果"] = {"collected": []}
	scene.active_order.append("水果")
	scene._render()

	var category_slot := _find_button_with_meta(scene, "category_slot")
	if category_slot == null:
		push_error("No hover smoke failed: category slot not found")
		quit(1)
		return false
	if category_slot.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		push_error("No hover smoke failed: category slot still receives hover")
		quit(1)
		return false
	if not (category_slot.get_theme_stylebox("focus") is StyleBoxEmpty):
		push_error("No hover smoke failed: category slot focus style is visible")
		quit(1)
		return false

	var settings := _find_button_with_meta(scene, "settings_button")
	if settings == null:
		push_error("No hover smoke failed: settings button not found")
		quit(1)
		return false
	if settings.get_theme_stylebox("hover") != settings.get_theme_stylebox("normal"):
		push_error("No hover smoke failed: settings hover style differs from normal")
		quit(1)
		return false
	if not (settings.get_theme_stylebox("focus") is StyleBoxEmpty):
		push_error("No hover smoke failed: settings focus style is visible")
		quit(1)
		return false

	settings.pressed.emit()
	var music := _find_button_with_meta(scene, "music_toggle_button")
	if music == null:
		push_error("No hover smoke failed: music toggle not found")
		quit(1)
		return false
	if music.get_theme_stylebox("hover") != music.get_theme_stylebox("normal"):
		push_error("No hover smoke failed: music toggle hover style differs from normal")
		quit(1)
		return false
	if not (music.get_theme_stylebox("focus") is StyleBoxEmpty):
		push_error("No hover smoke failed: music toggle focus style is visible")
		quit(1)
		return false

	print("NO_HOVER_SMOKE_PASS")
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
