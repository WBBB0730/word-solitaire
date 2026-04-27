extends SceneTree


func _initialize() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene._ready()
	scene.menu_active = false
	scene.game_over = false
	scene.steps_left = 3
	scene.categories = {"家具": ["桌子", "椅子", "沙发"]}
	scene.word_to_category = {"桌子": "家具", "椅子": "家具", "沙发": "家具"}
	scene.deck = [scene._category("家具", false)]
	scene.draw_stack.clear()
	scene.columns = [[], [], [], []]
	scene.active_categories.clear()
	scene.active_order.clear()

	scene._handle_deck_pressed()

	if scene.game_over:
		push_error("Last draw not stuck smoke failed: last drawn movable card triggered game over")
		quit(1)
		return
	if scene.draw_stack.size() != 1:
		push_error("Last draw not stuck smoke failed: drawn card was not added to draw stack")
		quit(1)
		return
	if not scene._has_any_legal_move():
		push_error("Last draw not stuck smoke failed: drawn category is not considered movable")
		quit(1)
		return
	if scene.status_text == "无法移动":
		push_error("Last draw not stuck smoke failed: status still says unable to move")
		quit(1)
		return

	print("LAST_DRAW_NOT_STUCK_SMOKE_PASS")
	quit(0)
