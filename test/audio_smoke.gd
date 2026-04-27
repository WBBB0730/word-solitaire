extends SceneTree

var scene: Node
var checked := false


func _initialize() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)


func _process(_delta: float) -> bool:
	if checked:
		return false
	checked = true

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
	quit(0)
	return false


func _stream_has_loop(stream: AudioStream) -> bool:
	for property in stream.get_property_list():
		if property.get("name", "") == "loop":
			return true
	return false
