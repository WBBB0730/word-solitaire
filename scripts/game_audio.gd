## 管理主场景的背景音乐和短音效播放器。
## 为了兼容现有冒烟测试和调试脚本，会把公开音频字段同步回主场景。
class_name GameAudio
extends RefCounted

## 接收音频播放器子节点的游戏场景。
var game: Node

## 循环背景音乐播放器。
var music_player: AudioStreamPlayer

## 翻牌音效共用音频流。
var card_flip_sfx_stream: AudioStream

## 按钮点击音效共用音频流。
var button_click_sfx_stream: AudioStream

## 翻牌音效播放器池，允许短时间重叠播放。
var sfx_players: Array = []

## 按钮音效播放器池，允许短时间重叠播放。
var button_sfx_players: Array = []

var next_sfx_player := 0
var next_button_sfx_player := 0
var audio_initialized := false


func _init(game_scene: Node) -> void:
	game = game_scene


## 创建音乐和音效播放器，并挂到主场景节点树。
func init_audio() -> void:
	if audio_initialized:
		_mirror_to_game()
		return
	audio_initialized = true

	var music_stream: AudioStream = load(game.MUSIC_PATH)
	if music_stream != null:
		set_audio_stream_loop(music_stream, true)
		music_player = AudioStreamPlayer.new()
		music_player.set_meta("audio_player", true)
		music_player.name = "MusicPlayer"
		music_player.stream = music_stream
		music_player.volume_db = game.MUSIC_VOLUME_DB
		game.add_child(music_player)
		if music_player.is_inside_tree():
			music_player.play()
		else:
			game.call_deferred("_play_background_music")

	card_flip_sfx_stream = load(game.CARD_FLIP_SFX_PATH)
	for i in range(int(game.SFX_PLAYER_COUNT)):
		var player := AudioStreamPlayer.new()
		player.set_meta("audio_player", true)
		player.name = "CardFlipSfx" + str(i + 1)
		player.stream = card_flip_sfx_stream
		player.volume_db = game.CARD_FLIP_SFX_VOLUME_DB
		game.add_child(player)
		sfx_players.append(player)

	button_click_sfx_stream = load(game.BUTTON_CLICK_SFX_PATH)
	for i in range(int(game.BUTTON_SFX_PLAYER_COUNT)):
		var player := AudioStreamPlayer.new()
		player.set_meta("audio_player", true)
		player.name = "ButtonClickSfx" + str(i + 1)
		player.stream = button_click_sfx_stream
		player.volume_db = game.BUTTON_CLICK_SFX_VOLUME_DB
		game.add_child(player)
		button_sfx_players.append(player)

	_mirror_to_game()


## 如果音频流支持循环属性，则设置循环播放。
static func set_audio_stream_loop(stream: AudioStream, enabled: bool) -> void:
	for property in stream.get_property_list():
		if property.get("name", "") == "loop":
			stream.set("loop", enabled)
			return


## 在延迟挂树后播放背景音乐。
func play_background_music() -> void:
	if is_instance_valid(music_player) and music_player.is_inside_tree() and not music_player.playing:
		music_player.play()
	_mirror_to_game()


## 播放带轻微音高变化的翻牌音效。
func play_card_flip_sfx() -> void:
	if card_flip_sfx_stream == null or sfx_players.is_empty():
		return
	var player: AudioStreamPlayer = sfx_players[next_sfx_player % sfx_players.size()]
	next_sfx_player += 1
	if not is_instance_valid(player) or not player.is_inside_tree():
		_mirror_to_game()
		return
	player.stop()
	player.pitch_scale = randf_range(0.97, 1.03)
	player.play()
	_mirror_to_game()


## 只给真正的按钮播放点击音效，不影响卡牌触摸区域。
func play_button_click_sfx() -> void:
	if button_click_sfx_stream == null or button_sfx_players.is_empty():
		return
	var player: AudioStreamPlayer = button_sfx_players[next_button_sfx_player % button_sfx_players.size()]
	next_button_sfx_player += 1
	if not is_instance_valid(player) or not player.is_inside_tree():
		_mirror_to_game()
		return
	player.stop()
	player.pitch_scale = randf_range(0.98, 1.02)
	player.play()
	_mirror_to_game()


## 同步主场景上的旧公开字段，方便测试和诊断继续读取。
func _mirror_to_game() -> void:
	game.music_player = music_player
	game.card_flip_sfx_stream = card_flip_sfx_stream
	game.button_click_sfx_stream = button_click_sfx_stream
	game.sfx_players = sfx_players
	game.button_sfx_players = button_sfx_players
	game.next_sfx_player = next_sfx_player
	game.next_button_sfx_player = next_button_sfx_player
	game.audio_initialized = audio_initialized


## 通用音量公式：分组基础响度 + 单个素材微调。
static func balanced_volume_db(group_volume_db: float, asset_trim_db: float) -> float:
	return group_volume_db + asset_trim_db
