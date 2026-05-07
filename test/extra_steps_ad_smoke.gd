extends SceneTree

const TEMP_SETTINGS_PATH := "user://extra_steps_ad_smoke.cfg"

var scene: Node
var phase := 0


func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
	scene = load("res://scenes/main.tscn").instantiate()
	scene.user_settings_path = TEMP_SETTINGS_PATH
	root.add_child(scene)
	scene._ready()
	scene.ad_service.set_editor_bypass_enabled(true)


func _process(_delta: float) -> bool:
	if scene.pending_rewarded_placement != "":
		return false
	if phase == 0:
		phase = 1
		_prepare_step_out_state()
		return false
	if phase == 1:
		phase = 2
		_start_extra_steps_ad()
		return false
	if phase == 2:
		phase = 3
		_check_rewarded_steps()
		_check_once_per_round()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
		print("EXTRA_STEPS_AD_SMOKE_PASS")
		quit(0)
	return false


func _prepare_step_out_state() -> void:
	scene._clear_transient_interaction_state()
	scene.tutorial_completed = true
	scene.menu_active = false
	scene.settings_menu_open = false
	scene.game_over = true
	scene.status_text = "步数用完"
	scene.steps_left = 0
	scene.extra_steps_ad_used = false
	scene.categories = {"水果": ["苹果", "香蕉"]}
	scene.word_to_category = {"苹果": "水果", "香蕉": "水果"}
	scene.next_card_id = 1
	scene.deck = []
	scene.draw_stack = [scene._word("苹果", true)]
	scene.columns = [[scene._word("香蕉", true)], [], [], []]
	scene.active_categories.clear()
	scene.active_order.clear()
	scene.prop_system.reset_round()
	scene._render()


func _start_extra_steps_ad() -> void:
	var ad_button := _find_button_with_meta(scene, "extra_steps_ad_button")
	_assert(ad_button != null and ad_button.text == "增加步数", "step-out overlay shows add-steps ad button")
	_assert(_find_node_with_meta(ad_button, "ad_play_icon") != null, "add-steps button shows ad icon")
	scene._on_extra_steps_ad_pressed()


func _check_rewarded_steps() -> void:
	_assert(scene.steps_left == 20, "rewarded ad adds 20 steps, got " + str(scene.steps_left))
	_assert(not scene.game_over, "rewarded ad resumes the round")
	_assert(scene.extra_steps_ad_used, "rewarded ad is marked used")


func _check_once_per_round() -> void:
	scene.steps_left = 0
	scene._check_end_state()
	scene._render()
	_assert(scene.game_over and scene.status_text == "步数用完", "step-out can happen again after reward is spent")
	_assert(_find_button_with_meta(scene, "extra_steps_ad_button") == null, "extra steps ad appears at most once per round")


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


func _assert(condition: bool, label: String) -> void:
	if not condition:
		push_error("Extra steps ad smoke failed: " + label)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
		quit(1)
