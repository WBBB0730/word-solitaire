## 非正式包广告后门 Provider。
##
## `ad_bypass` 导出特性会直接启用；编辑器运行时需要输入秘籍后才启用。
class_name DebugAdProvider
extends RefCounted

var game: Node
var editor_bypass_enabled := false


func _init(game_scene: Node) -> void:
	game = game_scene


## 当前是否可以模拟激励广告成功。
func is_available() -> bool:
	return editor_bypass_enabled or OS.has_feature("ad_bypass")


## 切换编辑器运行时后门，只影响当前会话。
func toggle_editor_bypass() -> bool:
	editor_bypass_enabled = not editor_bypass_enabled
	return editor_bypass_enabled


## 测试入口：直接设置编辑器后门状态。
func set_editor_bypass_enabled(enabled: bool) -> void:
	editor_bypass_enabled = enabled


## 下一帧模拟广告完整观看，保留和真实 SDK 一样的异步形态。
func show_rewarded(placement: String) -> bool:
	if not is_available():
		return false
	game.call_deferred("_debug_complete_rewarded_ad", placement)
	return true
