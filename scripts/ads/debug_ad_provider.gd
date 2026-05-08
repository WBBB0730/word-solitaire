## 非正式包广告后门 Provider。
##
## Godot 编辑器运行时默认启用；`ad_bypass` 导出特性也会直接启用。
class_name DebugAdProvider
extends RefCounted

var game: Node
var editor_bypass_enabled := OS.has_feature("editor")


func _init(game_scene: Node) -> void:
	game = game_scene


## 当前是否可以模拟激励广告成功。
func is_available() -> bool:
	return editor_bypass_enabled or OS.has_feature("ad_bypass")


## 测试入口：直接设置编辑器后门状态。
func set_editor_bypass_enabled(enabled: bool) -> void:
	editor_bypass_enabled = enabled


## 下一帧模拟广告完整观看，保留和真实 SDK 一样的异步形态。
func show_rewarded(placement: String) -> bool:
	if not is_available():
		return false
	game.call_deferred("_debug_complete_rewarded_ad", placement)
	return true
