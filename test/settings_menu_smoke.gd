extends SceneTree

const TEMP_SETTINGS_PATH := "user://settings_menu_smoke.cfg"

var scene: Node
var checked := false
var capture_mode := false
var frames := 0


func _initialize() -> void:
	capture_mode = OS.get_cmdline_user_args().has("--capture")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
	scene = load("res://scenes/main.tscn").instantiate()
	scene.user_settings_path = TEMP_SETTINGS_PATH
	root.add_child(scene)
	if capture_mode:
		scene.menu_active = false
		scene.settings_menu_open = true
		scene._render()


func _process(_delta: float) -> bool:
	if capture_mode:
		frames += 1
		scene.menu_active = false
		scene.settings_menu_open = true
		scene._render()
		return false

	if checked:
		return false
	checked = true

	if not scene.music_enabled or not scene.sfx_enabled:
		push_error("Settings menu smoke failed: defaults should enable audio")
		_cleanup_and_quit(1)
		return false

	var before_clicks: int = scene.next_button_sfx_player
	scene._on_sfx_toggle_pressed()
	if scene.sfx_enabled:
		push_error("Settings menu smoke failed: sfx toggle did not turn off")
		_cleanup_and_quit(1)
		return false
	if scene.next_button_sfx_player != before_clicks:
		push_error("Settings menu smoke failed: turning sfx off played a click sound")
		_cleanup_and_quit(1)
		return false

	scene._on_sfx_toggle_pressed()
	if not scene.sfx_enabled:
		push_error("Settings menu smoke failed: sfx toggle did not turn on")
		_cleanup_and_quit(1)
		return false
	if scene.next_button_sfx_player != before_clicks + 1:
		push_error("Settings menu smoke failed: turning sfx on did not play a click sound")
		_cleanup_and_quit(1)
		return false

	scene.menu_active = false
	scene.settings_menu_open = true
	scene._render()
	var close_button := _find_meta_button(scene, "settings_close_button")
	if close_button == null:
		push_error("Settings menu smoke failed: top-right close button should be rendered")
		_cleanup_and_quit(1)
		return false
	if close_button.text != "":
		push_error("Settings menu smoke failed: close button should use drawn icon instead of text")
		_cleanup_and_quit(1)
		return false
	if _count_buttons_with_meta(scene, "settings_close_button") != 1:
		push_error("Settings menu smoke failed: should render only one close button")
		_cleanup_and_quit(1)
		return false
	close_button.pressed.emit()
	if scene.settings_menu_open:
		push_error("Settings menu smoke failed: close button did not close menu")
		_cleanup_and_quit(1)
		return false

	scene.settings_menu_open = true
	scene._render()
	if _find_bottom_continue_button(scene) != null:
		push_error("Settings menu smoke failed: bottom continue button should not be rendered")
		_cleanup_and_quit(1)
		return false
	var overlay := _find_settings_overlay(scene)
	if overlay == null:
		push_error("Settings menu smoke failed: settings overlay not found")
		_cleanup_and_quit(1)
		return false
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	overlay.gui_input.emit(click)
	if scene.settings_menu_open:
		push_error("Settings menu smoke failed: outside click did not close menu")
		_cleanup_and_quit(1)
		return false

	scene.music_enabled = false
	scene.sfx_enabled = false
	scene._save_user_settings()
	var next_scene: Node = load("res://scenes/main.tscn").instantiate()
	next_scene.user_settings_path = TEMP_SETTINGS_PATH
	next_scene._load_user_settings()
	if next_scene.music_enabled or next_scene.sfx_enabled:
		push_error("Settings menu smoke failed: persisted audio settings were not restored")
		next_scene.free()
		_cleanup_and_quit(1)
		return false
	next_scene.free()

	print("SETTINGS_MENU_SMOKE_PASS")
	_cleanup_and_quit(0)
	return false


func _cleanup_and_quit(code: int) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
	quit(code)


func _find_settings_overlay(node: Node) -> ColorRect:
	for child in node.get_children():
		if child is ColorRect and child.has_meta("settings_menu_overlay"):
			return child
		var nested := _find_settings_overlay(child)
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


func _count_buttons_with_meta(node: Node, meta_name: String) -> int:
	var count := 0
	for child in node.get_children():
		if child is Button and child.has_meta(meta_name):
			count += 1
		count += _count_buttons_with_meta(child, meta_name)
	return count


func _find_bottom_continue_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and child.text == "继续游戏":
			return child
		var nested := _find_bottom_continue_button(child)
		if nested != null:
			return nested
	return null
