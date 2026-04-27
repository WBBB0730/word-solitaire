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
	scene.categories = {"明清小说": ["水浒传", "红楼梦", "西游记", "三国演义", "金瓶梅", "儒林外史"]}
	scene.active_categories.clear()
	scene.active_order.clear()
	scene.active_categories["明清小说"] = {"collected": ["水浒传", "红楼梦"]}
	scene.active_order.append("明清小说")
	scene.deck.clear()
	scene.draw_stack.clear()
	scene.columns = [
		[scene._category("明清小说")],
		[],
		[],
		[],
	]
	scene._render()

	var slot := _find_button_with_meta(scene, "category_slot")
	if slot == null:
		push_error("Category number font smoke failed: category slot not found")
		quit(1)
		return false
	_assert_split_category_labels(slot, "明清小说", "2/6", "slot")

	var board_card := _find_card_button(scene, scene.columns[0][0]["id"])
	if board_card == null:
		push_error("Category number font smoke failed: board category not found")
		quit(1)
		return false
	_assert_split_category_labels(board_card, "明清小说", "0/6", "board")

	print("CATEGORY_NUMBER_FONT_SMOKE_PASS")
	quit(0)
	return false


func _assert_split_category_labels(node: Node, name_text: String, progress_text: String, label: String) -> void:
	var name_label := _find_label(node, name_text)
	var progress_label := _find_label(node, progress_text)
	if name_label == null or progress_label == null:
		push_error("Category number font smoke failed: missing split labels on " + label)
		quit(1)
		return
	if name_label.get_theme_font_size("font_size") >= progress_label.get_theme_font_size("font_size"):
		push_error("Category number font smoke failed: number font did not stay fixed/larger on " + label)
		quit(1)
		return
	if progress_label.get_theme_font_size("font_size") != 16:
		push_error("Category number font smoke failed: number font is not fixed on " + label)
		quit(1)
		return


func _find_button_with_meta(node: Node, meta_name: String) -> Button:
	for child in node.get_children():
		if child is Button and child.has_meta(meta_name):
			return child
		var nested := _find_button_with_meta(child, meta_name)
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


func _find_label(node: Node, text: String) -> Label:
	for child in node.get_children():
		if child is Label and child.text == text:
			return child
		var nested := _find_label(child, text)
		if nested != null:
			return nested
	return null
