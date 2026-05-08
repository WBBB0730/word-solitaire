extends SceneTree

const TEMP_SETTINGS_PATH := "user://audio_smoke.cfg"

var scene: Node
var checked := false


func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
	scene = load("res://scenes/main.tscn").instantiate()
	scene.user_settings_path = TEMP_SETTINGS_PATH
	root.add_child(scene)


func _process(_delta: float) -> bool:
	if checked:
		return false
	checked = true

	var disabled_scene: Node = load("res://scenes/main.tscn").instantiate()
	disabled_scene.user_settings_path = TEMP_SETTINGS_PATH
	_write_audio_settings(TEMP_SETTINGS_PATH, false, true)
	root.add_child(disabled_scene)
	if disabled_scene.music_enabled:
		push_error("Audio smoke failed: disabled music setting was not loaded")
		disabled_scene.queue_free()
		quit(1)
		return false
	if disabled_scene.music_player.playing:
		push_error("Audio smoke failed: disabled music started during initialization")
		disabled_scene.queue_free()
		quit(1)
		return false
	disabled_scene._play_button_click_sfx()
	disabled_scene._sync_audio_enabled_state()
	if disabled_scene.music_player.playing:
		push_error("Audio smoke failed: disabled music started after first interaction")
		disabled_scene.queue_free()
		quit(1)
		return false
	disabled_scene.queue_free()

	if not is_instance_valid(scene.music_player):
		push_error("Audio smoke failed: music player was not created")
		quit(1)
		return false
	if scene.music_player.stream == null:
		push_error("Audio smoke failed: music stream was not loaded")
		quit(1)
		return false
	if scene.music_player.stream.resource_path != "res://assets/audio/background_music.mp3":
		push_error("Audio smoke failed: music stream path is wrong")
		quit(1)
		return false
	if abs(scene.music_player.volume_db - scene.MUSIC_VOLUME_DB) > 0.001:
		push_error("Audio smoke failed: music volume does not use the balanced constant")
		quit(1)
		return false
	if abs(scene.MUSIC_VOLUME_DB - scene._audio_balanced_volume_db(scene.MUSIC_BASE_VOLUME_DB, scene.MUSIC_TRIM_DB)) > 0.001:
		push_error("Audio smoke failed: music volume is not derived from base plus trim")
		quit(1)
		return false
	scene.music_enabled = false
	scene._sync_audio_enabled_state()
	if scene.music_player.playing:
		push_error("Audio smoke failed: disabled music should stop instead of pausing")
		quit(1)
		return false
	scene._play_button_click_sfx()
	scene._sync_audio_enabled_state()
	if scene.music_player.playing:
		push_error("Audio smoke failed: disabled music restarted after input-like action")
		quit(1)
		return false
	scene.music_enabled = true
	scene._sync_audio_enabled_state()
	if not scene.music_player.playing:
		push_error("Audio smoke failed: re-enabled music did not start")
		quit(1)
		return false
	scene._on_rewarded_ad_started("prop_hint")
	if not scene.music_player.stream_paused:
		push_error("Audio smoke failed: rewarded ad did not pause music")
		quit(1)
		return false
	scene.music_player.stop()
	scene._on_rewarded_ad_failed("prop_hint", "dismissed")
	if scene.music_player.stream_paused:
		push_error("Audio smoke failed: music did not resume after rewarded ad")
		quit(1)
		return false
	if not scene.music_player.playing or abs(scene.music_player.get_playback_position() - scene.music_resume_position) > 0.25:
		push_error("Audio smoke failed: interrupted ad pause did not resume near the saved music position")
		quit(1)
		return false
	scene._set_app_state_music_paused(true)
	if not scene.music_player.stream_paused:
		push_error("Audio smoke failed: app background/focus loss did not pause music")
		quit(1)
		return false
	scene._on_rewarded_ad_started("prop_hint")
	scene._on_rewarded_ad_failed("prop_hint", "dismissed")
	if not scene.music_player.stream_paused:
		push_error("Audio smoke failed: ending ad should not resume while app is still backgrounded")
		quit(1)
		return false
	scene.music_enabled = false
	scene._sync_audio_enabled_state()
	if scene.music_player.playing or scene.music_player.stream_paused:
		push_error("Audio smoke failed: disabled music should stop even while app is backgrounded")
		quit(1)
		return false
	scene.music_enabled = true
	scene._sync_audio_enabled_state()
	if scene.music_player.playing:
		push_error("Audio smoke failed: music should not start while app is backgrounded")
		quit(1)
		return false
	scene._set_app_state_music_paused(false)
	if not scene.music_player.playing or scene.music_player.stream_paused:
		push_error("Audio smoke failed: music did not resume after app foreground/focus return")
		quit(1)
		return false
	if _stream_has_loop(scene.music_player.stream) and not bool(scene.music_player.stream.get("loop")):
		push_error("Audio smoke failed: music stream is not set to loop")
		quit(1)
		return false
	if scene.sfx_players.size() != scene.SFX_PLAYER_COUNT:
		push_error("Audio smoke failed: sfx pool size is wrong")
		quit(1)
		return false
	if scene.card_flip_sfx_stream == null or scene.card_flip_sfx_stream.resource_path != "res://assets/audio/card_flip.wav":
		push_error("Audio smoke failed: card flip stream was not loaded")
		quit(1)
		return false
	for player in scene.sfx_players:
		if abs(player.volume_db - scene.CARD_FLIP_SFX_VOLUME_DB) > 0.001:
			push_error("Audio smoke failed: card flip volume does not use the balanced constant")
			quit(1)
			return false
	if abs(scene.CARD_FLIP_SFX_VOLUME_DB - scene._audio_balanced_volume_db(scene.SFX_BASE_VOLUME_DB, scene.CARD_FLIP_SFX_TRIM_DB)) > 0.001:
		push_error("Audio smoke failed: card flip volume is not derived from base plus trim")
		quit(1)
		return false
	if scene.button_sfx_players.size() != scene.BUTTON_SFX_PLAYER_COUNT:
		push_error("Audio smoke failed: button sfx pool size is wrong")
		quit(1)
		return false
	if scene.button_click_sfx_stream == null or scene.button_click_sfx_stream.resource_path != "res://assets/audio/button_click.mp3":
		push_error("Audio smoke failed: button click stream was not loaded")
		quit(1)
		return false
	for player in scene.button_sfx_players:
		if abs(player.volume_db - scene.BUTTON_CLICK_SFX_VOLUME_DB) > 0.001:
			push_error("Audio smoke failed: button click volume does not use the balanced constant")
			quit(1)
			return false
	if abs(scene.BUTTON_CLICK_SFX_VOLUME_DB - scene._audio_balanced_volume_db(scene.SFX_BASE_VOLUME_DB, scene.BUTTON_CLICK_SFX_TRIM_DB)) > 0.001:
		push_error("Audio smoke failed: button click volume is not derived from base plus trim")
		quit(1)
		return false

	scene._render()
	if not is_instance_valid(scene.music_player):
		push_error("Audio smoke failed: music player was removed by render")
		quit(1)
		return false
	for player in scene.sfx_players:
		if not is_instance_valid(player):
			push_error("Audio smoke failed: sfx player was removed by render")
			quit(1)
			return false
	for player in scene.button_sfx_players:
		if not is_instance_valid(player):
			push_error("Audio smoke failed: button sfx player was removed by render")
			quit(1)
			return false

	print("AUDIO_SMOKE_PASS")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
	quit(0)
	return false


func _stream_has_loop(stream: AudioStream) -> bool:
	for property in stream.get_property_list():
		if property.get("name", "") == "loop":
			return true
	return false


func _write_audio_settings(settings_path: String, music: bool, sfx: bool) -> void:
	var config := ConfigFile.new()
	config.set_value(scene.USER_SETTINGS_SECTION, "music_enabled", music)
	config.set_value(scene.USER_SETTINGS_SECTION, "sfx_enabled", sfx)
	config.save(settings_path)
