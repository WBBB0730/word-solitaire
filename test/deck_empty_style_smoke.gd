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
	scene._ready()
	scene.menu_active = false

	scene.deck = [scene._word("苹果", false)]
	scene.draw_stack.clear()
	scene._render()
	var full_deck := _find_deck_button(scene)
	if full_deck == null:
		push_error("Deck empty style smoke failed: full deck button not found")
		quit(1)
		return false
	var deck_title := _find_label(full_deck, "牌堆")
	var deck_count := _find_label(full_deck, "剩余1张")
	if deck_title == null or deck_count == null:
		push_error("Deck empty style smoke failed: full deck count omits unit")
		quit(1)
		return false
	if deck_title.get_theme_font_size("font_size") != 17:
		push_error("Deck empty style smoke failed: deck title font changed")
		quit(1)
		return false
	if deck_count.get_theme_font_size("font_size") >= deck_title.get_theme_font_size("font_size"):
		push_error("Deck empty style smoke failed: deck count font is not smaller")
		quit(1)
		return false
	if _has_deck_dash(full_deck):
		push_error("Deck empty style smoke failed: full deck shows dashed outline")
		quit(1)
		return false
	var full_style := _deck_surface_style(full_deck)
	if not (full_style is StyleBoxFlat) or full_style.bg_color.a < 0.99:
		push_error("Deck empty style smoke failed: full deck is not card-back filled")
		quit(1)
		return false

	scene.deck.clear()
	scene.draw_stack = [scene._word("香蕉", true)]
	scene._render()
	var empty_deck := _find_deck_button(scene)
	if empty_deck == null:
		push_error("Deck empty style smoke failed: empty deck button not found")
		quit(1)
		return false
	if _find_label(empty_deck, "点击洗牌") == null:
		push_error("Deck empty style smoke failed: wash text is not click-to-wash")
		quit(1)
		return false
	if not _has_deck_dash(empty_deck):
		push_error("Deck empty style smoke failed: empty deck has no dashed outline")
		quit(1)
		return false
	var empty_style := _deck_surface_style(empty_deck)
	if not (empty_style is StyleBoxFlat) or empty_style.bg_color.a > 0.01:
		push_error("Deck empty style smoke failed: empty deck is still filled")
		quit(1)
		return false
	if empty_deck is Button:
		push_error("Deck empty style smoke failed: deck still uses Button input")
		quit(1)
		return false

	if not capture_mode:
		print("DECK_EMPTY_STYLE_SMOKE_PASS")
		quit(0)
	return false


func _find_deck_button(node: Node) -> Control:
	for child in node.get_children():
		if _has_queued_ancestor(child):
			continue
		if child is Control and child.has_meta("deck_button"):
			return child
		var nested := _find_deck_button(child)
		if nested != null:
			return nested
	return null


func _deck_surface_style(deck_node: Node) -> StyleBox:
	for child in deck_node.get_children():
		if child is Panel and child.has_meta("deck_surface"):
			return child.get_theme_stylebox("panel")
	return null


func _has_deck_dash(node: Node) -> bool:
	for child in node.get_children():
		if _has_queued_ancestor(child):
			continue
		if child.has_meta("deck_dash"):
			return true
		if _has_deck_dash(child):
			return true
	return false


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


func _has_queued_ancestor(node: Node) -> bool:
	var current := node
	while current != null:
		if current.is_queued_for_deletion():
			return true
		current = current.get_parent()
	return false
