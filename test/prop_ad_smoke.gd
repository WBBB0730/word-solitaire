extends SceneTree

const TEMP_SETTINGS_PATH := "user://prop_ad_smoke.cfg"

var scene: Node
var phase := 0


func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
	scene = load("res://scenes/main.tscn").instantiate()
	scene.user_settings_path = TEMP_SETTINGS_PATH
	root.add_child(scene)
	scene._ready()
	scene.ad_service.set_editor_bypass_enabled(false)
	_prepare_hint_ad_state()


func _process(_delta: float) -> bool:
	if scene.pending_rewarded_placement != "":
		return false
	if phase == 0:
		phase = 1
		_check_zero_inventory_ad_entry_without_provider()
		scene.ad_service.set_editor_bypass_enabled(true)
		_prepare_hint_ad_state()
		return false
	if phase == 1:
		phase = 2
		_start_hint_ad()
		return false
	if phase == 2:
		phase = 3
		_check_hint_ad()
		_prepare_undo_ad_state()
		return false
	if phase == 3:
		phase = 4
		_start_undo_ad()
		return false
	if phase == 4:
		phase = 5
		_check_undo_ad()
		_check_unavailable_zero_inventory_still_shows_ad_badge()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
		print("PROP_AD_SMOKE_PASS")
		quit(0)
	return false


func _prepare_hint_ad_state() -> void:
	_prepare_base_state()
	scene.prop_system.set_count(scene.PropSystemScript.PROP_HINT, 0)
	scene.prop_system.set_count(scene.PropSystemScript.PROP_UNDO, 1)
	scene._render()


func _check_zero_inventory_ad_entry_without_provider() -> void:
	var hint_button := _find_button_with_meta(scene, "hint_prop_button")
	_assert(hint_button != null and not hint_button.disabled, "zero hint still shows clickable ad entry before provider is available")
	var ad_badge := _find_node_with_meta(hint_button, "prop_ad_badge")
	_assert(ad_badge != null, "zero hint shows ad badge before provider is available")
	_assert(_canvas_z_total(ad_badge) < 260, "prop ad badge stays below round transition curtain")
	var ad_icon := _find_node_with_meta(hint_button, "ad_play_icon")
	_assert(ad_icon != null and _canvas_z_total(ad_icon) < 260, "prop ad icon stays below round transition curtain")
	scene._on_hint_prop_pressed()
	_assert(scene.prop_system.count(scene.PropSystemScript.PROP_HINT) == 0, "unavailable ad does not grant hint")
	_assert(scene.prop_system.hint_guidance().is_empty(), "unavailable ad does not display hint")
	_assert(scene.status_text == "广告暂不可用", "unavailable ad gives clear feedback")


func _start_hint_ad() -> void:
	var hint_button := _find_button_with_meta(scene, "hint_prop_button")
	_assert(hint_button != null and not hint_button.disabled, "hint is clickable when ad can refill it")
	_assert(_find_node_with_meta(hint_button, "prop_ad_badge") != null, "hint shows ad badge at zero inventory")
	scene._on_hint_prop_pressed()


func _check_hint_ad() -> void:
	_assert(scene.prop_system.count(scene.PropSystemScript.PROP_HINT) == 0, "hint ad reward is immediately consumed")
	_assert(not scene.prop_system.hint_guidance().is_empty(), "hint ad immediately displays guidance")


func _prepare_undo_ad_state() -> void:
	_prepare_base_state()
	scene.prop_system.set_count(scene.PropSystemScript.PROP_HINT, 1)
	scene.prop_system.set_count(scene.PropSystemScript.PROP_UNDO, 0)
	scene.prop_system.push_undo_snapshot()
	scene.draw_stack.clear()
	scene.status_text = "changed"
	scene._render()


func _start_undo_ad() -> void:
	var undo_button := _find_button_with_meta(scene, "undo_prop_button")
	_assert(undo_button != null and not undo_button.disabled, "undo is clickable when ad can refill it")
	_assert(_find_node_with_meta(undo_button, "prop_ad_badge") != null, "undo shows ad badge at zero inventory")
	scene._on_undo_prop_pressed()


func _check_undo_ad() -> void:
	_assert(scene.prop_system.count(scene.PropSystemScript.PROP_UNDO) == 0, "undo ad reward is immediately consumed")
	_assert(scene.draw_stack.size() == 1, "undo ad immediately restores previous state")


func _check_unavailable_zero_inventory_still_shows_ad_badge() -> void:
	_prepare_base_state()
	scene.prop_system.set_count(scene.PropSystemScript.PROP_UNDO, 0)
	scene.prop_system.undo_stack.clear()
	scene._render()
	var undo_button := _find_button_with_meta(scene, "undo_prop_button")
	_assert(undo_button != null and undo_button.disabled, "zero undo is disabled without undo history")
	_assert(_find_node_with_meta(undo_button, "prop_ad_badge") != null, "disabled zero undo still shows ad badge")
	_assert(_find_node_with_meta(undo_button, "prop_count_badge") == null, "disabled zero undo does not show numeric zero badge")


func _prepare_base_state() -> void:
	scene._clear_transient_interaction_state()
	scene.tutorial_completed = true
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
	scene.status_text = "prop ad smoke"
	scene.prop_system.reset_round()
	scene.prop_system.clear_hint()


func _find_button_with_meta(node: Node, meta_name: String) -> Button:
	for child in node.get_children():
		if child is Button and child.has_meta(meta_name):
			return child
		var nested := _find_button_with_meta(child, meta_name)
		if nested != null:
			return nested
	return null


func _find_node_with_meta(node: Node, meta_name: String) -> Node:
	for child in node.get_children():
		if child.has_meta(meta_name):
			return child
		var nested := _find_node_with_meta(child, meta_name)
		if nested != null:
			return nested
	return null


func _canvas_z_total(node: Node) -> int:
	var total := 0
	var cursor := node
	while cursor != null:
		if cursor is CanvasItem:
			total = int(cursor.z_index) + total if cursor.z_as_relative else int(cursor.z_index)
		cursor = cursor.get_parent()
	return total


func _assert(condition: bool, label: String) -> void:
	if not condition:
		push_error("Prop ad smoke failed: " + label)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
		quit(1)
