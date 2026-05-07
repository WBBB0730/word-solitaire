extends SceneTree

const TEMP_SETTINGS_PATH := "user://prop_system_smoke.cfg"

var scene: Node
var phase := 0


func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
	scene = load("res://scenes/main.tscn").instantiate()
	scene.user_settings_path = TEMP_SETTINGS_PATH
	root.add_child(scene)
	scene._ready()


func _process(_delta: float) -> bool:
	if phase == 0:
		phase = 1
		_check_visibility_and_hint()
		return false
	if phase == 1:
		phase = 2
		_check_undo()
		return false
	return false


func _check_visibility_and_hint() -> void:
	_prepare_simple_state(false)
	scene._render()
	_assert(_find_button_with_meta(scene, "hint_prop_button") == null, "props stay hidden before tutorial completion")

	_prepare_simple_state(true)
	scene._render()
	var hint_button := _find_button_with_meta(scene, "hint_prop_button")
	var undo_button := _find_button_with_meta(scene, "undo_prop_button")
	_assert(hint_button != null and undo_button != null, "props show after tutorial completion")
	_assert(hint_button.text == "" and undo_button.text == "", "prop buttons do not use text")
	_assert(_find_node_with_meta(hint_button, "prop_button_icon") != null and _find_node_with_meta(undo_button, "prop_button_icon") != null, "prop buttons render icons")
	_assert(_badge_text(hint_button) == "3" and _badge_text(undo_button) == "3", "prop counts render as badges")
	_assert(not hint_button.disabled, "hint is enabled when a legal move exists")
	_assert(undo_button.disabled, "undo is disabled before any action")

	scene._on_hint_prop_pressed()
	_assert(scene.prop_system.count("hint") == 2, "hint consumes one count")
	var updated_hint_button := _find_button_with_meta(scene, "hint_prop_button")
	_assert(updated_hint_button != null and _badge_text(updated_hint_button) == "2", "hint badge updates after use")
	var guidance: Dictionary = scene.prop_system.hint_guidance()
	_assert(String(guidance.get("gesture", "")) == "drag", "hint uses drag guidance")
	_assert(String(guidance.get("source", {}).get("kind", "")) == "draw_top", "hint points at draw top")
	_assert(String(guidance.get("target", {}).get("kind", "")) == "board_column", "hint points at a board column")
	_assert(_find_node_with_meta(scene, "tutorial_mask") != null, "hint reuses tutorial mask")
	_assert(not scene.prop_system.can_use_hint(), "hint is disabled while current hint is visible")
	scene._on_hint_prop_pressed()
	_assert(scene.prop_system.count("hint") == 2, "second hint press before an action does not consume count")


func _check_undo() -> void:
	_prepare_deck_state()
	scene._handle_deck_pressed()
	var drawn_id := int(scene.draw_stack[scene.draw_stack.size() - 1]["id"])
	scene._finish_draw_card_animation(drawn_id)
	_assert(scene.draw_stack.size() == 1 and scene.deck.is_empty(), "deck draw changes state")
	_assert(scene.steps_left == 9, "deck draw consumes a step")
	_assert(scene.prop_system.can_use_undo(), "undo becomes available after an action")

	scene._on_undo_prop_pressed()
	_assert(scene.deck.size() == 1 and scene.draw_stack.is_empty(), "undo restores deck and draw stack")
	_assert(scene.steps_left == 10, "undo restores step count")
	_assert(scene.prop_system.count("undo") == 2, "undo consumes one count")

	_prepare_simple_state(true)
	scene.selected = scene._selection_for_draw(scene.draw_stack.size() - 1)
	scene.drag_preview = Control.new()
	scene.drag_preview.size = Vector2(scene.CARD_W, scene.CARD_H)
	scene.add_child(scene.drag_preview)
	scene._drop_selected_at(_global_center(scene._board_column_rect(0)))
	_assert(scene.columns[0].size() == 2 and scene.draw_stack.is_empty(), "drag move changes state")
	_assert(scene.prop_system.can_use_undo(), "undo becomes available after a dragged move")
	scene._on_undo_prop_pressed()
	_assert(scene.columns[0].size() == 1 and scene.draw_stack.size() == 1, "undo restores dragged move")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
	print("PROP_SYSTEM_SMOKE_PASS")
	quit(0)


func _prepare_simple_state(completed: bool) -> void:
	scene._clear_transient_interaction_state()
	scene.tutorial_completed = completed
	scene.menu_active = false
	scene.game_over = false
	scene.settings_menu_open = false
	scene.categories = {"水果": ["苹果", "香蕉"]}
	scene.word_to_category = {"苹果": "水果", "香蕉": "水果"}
	scene.next_card_id = 1
	scene.deck = []
	scene.draw_stack = [scene._word("苹果", true)]
	scene.columns = [[scene._word("香蕉", true)], [], [], []]
	scene.active_categories.clear()
	scene.active_order.clear()
	scene.steps_left = 10
	scene.status_text = "prop smoke"
	scene.prop_system.reset_round()


func _prepare_deck_state() -> void:
	scene._clear_transient_interaction_state()
	scene.tutorial_completed = true
	scene.menu_active = false
	scene.game_over = false
	scene.settings_menu_open = false
	scene.categories = {"水果": ["苹果", "香蕉"]}
	scene.word_to_category = {"苹果": "水果", "香蕉": "水果"}
	scene.next_card_id = 1
	scene.deck = [scene._word("苹果", false)]
	scene.draw_stack = []
	scene.columns = [[scene._word("香蕉", true)], [], [], []]
	scene.active_categories.clear()
	scene.active_order.clear()
	scene.steps_left = 10
	scene.status_text = "prop smoke"
	scene.prop_system.reset_round()
	scene._render()


func _find_button_with_meta(node: Node, meta_name: String) -> Button:
	for child in node.get_children():
		if _has_queued_ancestor(child):
			continue
		if child is Button and child.has_meta(meta_name):
			return child
		var nested := _find_button_with_meta(child, meta_name)
		if nested != null:
			return nested
	return null


func _find_node_with_meta(node: Node, meta_name: String) -> Node:
	for child in node.get_children():
		if _has_queued_ancestor(child):
			continue
		if child.has_meta(meta_name):
			return child
		var nested := _find_node_with_meta(child, meta_name)
		if nested != null:
			return nested
	return null


func _badge_text(button: Button) -> String:
	var badge := _find_node_with_meta(button, "prop_count_badge")
	if badge == null:
		return ""
	var label := _find_first_label(badge)
	return "" if label == null else label.text


func _find_first_label(node: Node) -> Label:
	for child in node.get_children():
		if child is Label:
			return child
		var nested := _find_first_label(child)
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


func _global_center(rect: Rect2) -> Vector2:
	return scene.get_global_transform() * rect.get_center()


func _assert(condition: bool, label: String) -> void:
	if not condition:
		push_error("Prop system smoke failed: " + label)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
		quit(1)
