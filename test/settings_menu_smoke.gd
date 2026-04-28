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
