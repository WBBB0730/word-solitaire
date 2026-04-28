extends SceneTree


func _initialize() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	var ok := true
	ok = _assert(int(ProjectSettings.get_setting("display/window/size/viewport_width")) == 720, "viewport width should be 720") and ok
	ok = _assert(int(ProjectSettings.get_setting("display/window/size/viewport_height")) == 1280, "viewport height should be 1280") and ok
	ok = _assert(String(ProjectSettings.get_setting("display/window/stretch/aspect")) == "expand", "stretch aspect should expand for tall phones") and ok
	ok = _assert(_columns_fit_design_width(scene), "four card columns should fit inside 720 width") and ok
	ok = _assert(_board_fits_design_height(scene), "default six-card columns should fit inside 1280 height") and ok
	ok = _assert(_wide_safe_area_centers_game(scene), "wide safe area should keep game inside a centered 720-wide region") and ok
	ok = _assert(_top_buttons_keep_scaled_design_size(scene), "top buttons should preserve the old design proportions after scaling") and ok
	ok = _assert(scene._deck_rect().size == Vector2(scene.CARD_W, scene.CARD_H), "deck hitbox should match scaled card size") and ok
	scene.free()
	if not ok:
		quit(1)
		return
	print("RESOLUTION_LAYOUT_SMOKE_PASS")
	quit(0)


func _columns_fit_design_width(scene: Node) -> bool:
	var left: float = scene._column_x(0)
	var right: float = scene._column_x(scene.BOARD_COLUMN_COUNT - 1) + scene.CARD_W
	return left >= 0.0 and right <= scene.GAME_W


func _board_fits_design_height(scene: Node) -> bool:
	var board_bottom: float = scene.BOARD_Y + scene.CARD_H + float(scene.BOARD_CARDS_PER_COLUMN - 1) * scene.STACK_STEP
	return board_bottom <= scene.GAME_H


func _wide_safe_area_centers_game(scene: Node) -> bool:
	var origin: Vector2 = scene._play_area_origin_for_safe_rect(Rect2(Vector2(80, 32), Vector2(1880, 1280)))
	return origin == Vector2(660, 32)


func _top_buttons_keep_scaled_design_size(scene: Node) -> bool:
	return scene.TOP_BUTTON_W >= 90.0 and scene.TOP_BUTTON_H >= 50.0 and scene.STEPS_LABEL_Y > scene.TOP_CONTROL_Y + scene.TOP_BUTTON_H


func _assert(condition: bool, label: String) -> bool:
	if not condition:
		push_error("Resolution layout smoke failed: " + label)
		return false
	return true
