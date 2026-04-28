extends SceneTree

var scene: Node
var phase := 0
var original_deck_size := 0
var original_steps := 0


func _initialize() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene._ready()


func _process(_delta: float) -> bool:
	if phase == 0:
		scene.menu_active = false
		scene._render()
		scene._remember_layout_metrics()
		original_deck_size = scene.deck.size()
		original_steps = scene.steps_left
		phase = 1
		return false

	if phase == 1:
		scene.last_layout_viewport_size = Vector2(-1, -1)
		scene.last_layout_safe_rect = Rect2(Vector2(-1, -1), Vector2(1, 1))
		scene._request_layout_refresh()
		if not scene.layout_resize_refresh_pending:
			push_error("Runtime resize layout smoke failed: refresh was not queued")
			quit(1)
			return false
		phase = 2
		return false

	if phase == 2:
		if scene.layout_resize_refresh_pending:
			return false
		if scene.last_layout_viewport_size != scene.get_viewport_rect().size:
			push_error("Runtime resize layout smoke failed: viewport metric was not refreshed")
			quit(1)
			return false
		if scene.deck.size() != original_deck_size or scene.steps_left != original_steps:
			push_error("Runtime resize layout smoke failed: layout refresh changed game state deck=%d/%d steps=%d/%d" % [scene.deck.size(), original_deck_size, scene.steps_left, original_steps])
			quit(1)
			return false
		if not _top_controls_match_current_origin():
			push_error("Runtime resize layout smoke failed: top controls do not use current layout origin")
			quit(1)
			return false
		print("RUNTIME_RESIZE_LAYOUT_SMOKE_PASS")
		quit(0)
		return false

	return false


func _top_controls_match_current_origin() -> bool:
	var restart := _find_button_with_meta(scene, "restart_button")
	var home := _find_button_with_meta(scene, "home_button")
	if restart == null or home == null:
		return false
	var origin: Vector2 = scene._play_area_origin()
	var home_x: float = scene.TOP_CONTROL_X + scene.TOP_BUTTON_W + scene.TOP_BUTTON_GAP
	return restart.position == origin + Vector2(scene.TOP_CONTROL_X, scene.TOP_CONTROL_Y) and home.position == origin + Vector2(home_x, scene.TOP_CONTROL_Y)


func _find_button_with_meta(node: Node, meta_name: String) -> Button:
	for child in node.get_children():
		if child is Button and child.has_meta(meta_name):
			return child
		var nested := _find_button_with_meta(child, meta_name)
		if nested != null:
			return nested
	return null
