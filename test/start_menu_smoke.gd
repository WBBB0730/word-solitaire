extends SceneTree

const TEMP_SETTINGS_PATH := "user://start_menu_smoke.cfg"

var scene: Node
var capture_mode := false
var frames := 0
var phase := 0


func _initialize() -> void:
	capture_mode = OS.get_cmdline_user_args().has("--capture")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
	scene = load("res://scenes/main.tscn").instantiate()
	scene.user_settings_path = TEMP_SETTINGS_PATH
	root.add_child(scene)
	scene._ready()


func _process(_delta: float) -> bool:
	frames += 1
	if capture_mode:
		if frames > 2:
			quit(0)
		return false

	if phase == 0:
		var start_button := _find_start_button(scene)
		if start_button == null:
			push_error("Start menu smoke failed: start button not found")
			quit(1)
			return false
		if not scene.menu_active:
			push_error("Start menu smoke failed: menu did not start active")
			quit(1)
			return false
		if _find_tutorial_button(scene) != null:
			push_error("Start menu smoke failed: tutorial button should be hidden before completion")
			quit(1)
			return false
		if _find_home_settings_button(scene) != null:
			push_error("Start menu smoke failed: settings button should be hidden before completion")
			quit(1)
			return false
		if _count_buttons(scene) != 1:
			push_error("Start menu smoke failed: first-run menu should render start button only")
			quit(1)
			return false
		start_button.pressed.emit()
		if not scene._tutorial_active():
			push_error("Start menu smoke failed: first start should enter tutorial")
			quit(1)
			return false
		scene.tutorial_controller.finish()
		scene._render()
		phase = 1
		return false

	if phase == 1:
		if not scene.game_over or scene.status_text != "过关成功":
			push_error("Start menu smoke failed: tutorial completion should show normal success overlay")
			quit(1)
			return false
		scene._on_home_pressed()
		phase = 2
		return false

	if phase == 2:
		if not scene.menu_active:
			push_error("Start menu smoke failed: home did not return to menu")
			quit(1)
			return false
		var tutorial_button := _find_tutorial_button(scene)
		var settings_button := _find_home_settings_button(scene)
		if _find_start_button(scene) == null or tutorial_button == null or settings_button == null:
			push_error("Start menu smoke failed: completed menu should show start, tutorial, and settings buttons")
			quit(1)
			return false
		if _count_buttons(scene) != 3:
			push_error("Start menu smoke failed: completed menu should render exactly three buttons")
			quit(1)
			return false
		settings_button.pressed.emit()
		if not scene.settings_menu_open:
			push_error("Start menu smoke failed: home settings button should open settings menu")
			quit(1)
			return false
		if _find_meta_button(scene, "restart_button") != null or _find_meta_button(scene, "home_button") != null:
			push_error("Start menu smoke failed: home settings menu should only show audio controls")
			quit(1)
			return false
		scene._on_settings_close_pressed()
		tutorial_button = _find_tutorial_button(scene)
		if tutorial_button == null:
			push_error("Start menu smoke failed: tutorial button disappeared after closing settings")
			quit(1)
			return false
		tutorial_button.pressed.emit()
		if not scene._tutorial_active():
			push_error("Start menu smoke failed: tutorial button should restart tutorial")
			quit(1)
			return false
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
		print("START_MENU_SMOKE_PASS")
		quit(0)
		return false

	push_error("Start menu smoke failed: unexpected phase")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
	quit(1)
	return false


func _find_start_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and child.has_meta("start_button"):
			return child
		var nested := _find_start_button(child)
		if nested != null:
			return nested
	return null


func _find_tutorial_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and child.has_meta("tutorial_button"):
			return child
		var nested := _find_tutorial_button(child)
		if nested != null:
			return nested
	return null


func _find_home_settings_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and child.has_meta("home_settings_button"):
			return child
		var nested := _find_home_settings_button(child)
		if nested != null:
			return nested
	return null


func _find_meta_button(node: Node, meta_name: String) -> Button:
	for child in node.get_children():
		if child is Button and child.has_meta(meta_name):
			return child
		var nested := _find_meta_button(child, meta_name)
		if nested != null:
			return nested
	return null


func _count_buttons(node: Node) -> int:
	var count := 0
	for child in node.get_children():
		if child is Button:
			count += 1
		count += _count_buttons(child)
	return count
