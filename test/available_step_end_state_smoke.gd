extends SceneTree


func _initialize() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene._ready()

	_load_near_win_draw_state(scene)
	scene._check_end_state()
	if scene.game_over:
		push_error("Available step end state smoke failed: drawable matching word was treated as game over")
		quit(1)
		return
	if not scene._has_any_available_step():
		push_error("Available step end state smoke failed: draw stack was not counted as an available step")
		quit(1)
		return

	_load_pending_draw_animation_state(scene)
	scene._check_end_state()
	if scene.game_over:
		push_error("Available step end state smoke failed: pending draw animation was treated as game over")
		quit(1)
		return
	if not scene._has_any_available_step():
		push_error("Available step end state smoke failed: pending animation was not counted as an available step")
		quit(1)
		return

	_load_real_stuck_state(scene)
	scene._check_end_state()
	if not scene.game_over or scene.status_text != "无法移动":
		push_error("Available step end state smoke failed: real stuck state did not fail")
		quit(1)
		return

	print("AVAILABLE_STEP_END_STATE_SMOKE_PASS")
	quit(0)


func _load_near_win_draw_state(scene: Node) -> void:
	_reset_scene(scene)
	scene.draw_stack.append(scene._word("豆浆"))
	scene.active_categories["饮品"] = {"collected": ["绿茶", "咖啡", "牛奶", "橙汁", "可乐", "酸奶", "椰汁"]}
	scene.active_order.append("饮品")
	scene.active_order.append("")
	scene.active_order.append("")
	scene.active_order.append("")


func _load_pending_draw_animation_state(scene: Node) -> void:
	_reset_scene(scene)
	var card: Dictionary = scene._word("豆浆")
	scene.draw_animation_cards[card["id"]] = card
	scene.draw_flights[card["id"]] = {"elapsed": 0.0}
	scene.active_categories["饮品"] = {"collected": []}
	scene.active_order.append("饮品")


func _load_real_stuck_state(scene: Node) -> void:
	_reset_scene(scene)
	scene.active_categories["饮品"] = {"collected": []}
	scene.active_order.append("饮品")


func _reset_scene(scene: Node) -> void:
	scene.menu_active = false
	scene.game_over = false
	scene.steps_left = 2
	scene.status_text = "available step smoke"
	scene.categories = {"饮品": ["绿茶", "咖啡", "豆浆", "牛奶", "橙汁", "可乐", "酸奶", "椰汁"]}
	scene.word_to_category.clear()
	for word in scene.categories["饮品"]:
		scene.word_to_category[word] = "饮品"
	scene.deck.clear()
	scene.draw_stack.clear()
	scene.columns = [[], [], [], []]
	scene.active_categories.clear()
	scene.active_order.clear()
	scene.selected.clear()
	scene.drag_preview = null
	scene.returning_drag_preview = null
	scene.absorbing_drag_preview = null
	scene.draw_animation_cards.clear()
	scene.draw_flights.clear()
	scene.wash_flight.clear()
	scene.wash_animation_nodes.clear()
