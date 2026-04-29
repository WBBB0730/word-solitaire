extends SceneTree

const TEMP_SETTINGS_PATH := "user://tutorial_smoke.cfg"
const TutorialControllerScript := preload("res://scripts/tutorial_controller.gd")

var scene: Node


func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
	scene = load("res://scenes/main.tscn").instantiate()
	scene.user_settings_path = TEMP_SETTINGS_PATH
	root.add_child(scene)
	scene._start_tutorial()

	_assert(scene._tutorial_active(), "tutorial starts active")
	_assert(scene.tutorial_controller.allows_deck_press(), "first step allows deck")
	_assert(scene.deck.size() == 1 and scene.deck[0]["name"] == "苹果", "tutorial uses fixed deck")

	var wrong_selection: Dictionary = scene._selection_for_board(0, 0)
	scene._begin_drag_candidate(wrong_selection, Vector2.ZERO, Vector2.ZERO)
	_assert(scene.drag_candidate.is_empty(), "wrong source is blocked")

	scene._handle_deck_pressed()
	_assert(scene.draw_stack.size() == 1 and scene.draw_stack[0]["name"] == "苹果", "deck draw advances tutorial")
	_assert(_step_action() == "move_to_column", "step 2 waits for draw card to same-category word")

	scene.selected = scene._selection_for_draw(scene.draw_stack.size() - 1)
	scene._drop_selected_at(_global_center(scene._board_column_rect(0)))
	_assert(scene.columns[0].size() == 2, "draw card moves onto same-category word")
	_assert(_step_action() == "move_to_column", "step 3 waits for category card sealing word group")

	scene.selected = scene._selection_for_board(2, 0)
	scene._drop_selected_at(_global_center(scene._board_column_rect(0)))
	_assert(scene.columns[0].size() == 3 and scene.columns[0][2]["type"] == "category", "category card seals word group in area 4")
	_assert(_step_action() == "move_to_empty_category", "step 4 waits for sealed group to enter category area")

	scene.selected = scene._selection_for_board(0, scene.columns[0].size() - 1)
	scene._drop_selected_at(_global_center(scene._category_slot_rect(0)))
	_assert(scene.active_categories.has("水果"), "sealed group category enters area 3")
	_assert(scene.active_categories["水果"]["collected"].size() == 2, "sealed group words are absorbed")
	_assert(_step_action() == "move_to_active_category", "step 5 waits for completion group")

	scene.selected = scene._selection_for_board(3, scene.columns[3].size() - 1)
	scene._drop_selected_at(_global_center(scene._category_slot_rect(0)))
	_assert(_step_action() == "move_to_empty_category", "completion reveals direct-category card")
	_assert(scene.columns[3].size() == 1 and scene.columns[3][0]["type"] == "category" and scene.columns[3][0]["face_up"], "stationery category is revealed in the same deal")

	scene.selected = scene._selection_for_board(3, 0)
	scene._drop_selected_at(_global_center(scene._category_slot_rect(0)))
	_assert(scene.active_categories.has("文具"), "category card can enter area 3 directly")
	_assert(_step_action() == "move_to_active_category", "step 7 waits for stationery group absorption")

	scene.selected = scene._selection_for_board(1, scene.columns[1].size() - 1)
	scene._drop_selected_at(_global_center(scene._category_slot_rect(0)))
	_assert(not scene._tutorial_active(), "tutorial finishes after all core moves")
	_assert(scene.deck.is_empty() and scene.draw_stack.is_empty() and scene.active_categories.is_empty(), "tutorial deal is cleared")
	_assert(scene.tutorial_completed, "tutorial completion is saved in memory")
	_assert(TutorialControllerScript.load_completed(TEMP_SETTINGS_PATH), "tutorial completion persists")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
	print("TUTORIAL_SMOKE_PASS")
	quit(0)


func _step_action() -> String:
	return String(scene.tutorial_controller.current_step().get("action", ""))


func _global_center(rect: Rect2) -> Vector2:
	return scene.get_global_transform() * rect.get_center()


func _assert(condition: bool, label: String) -> void:
	if not condition:
		push_error("Tutorial smoke failed: " + label)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
		quit(1)
