## 广告服务入口。
##
## 游戏主逻辑只调用这里，不直接依赖具体广告 SDK。当前支持编辑器默认后门、
## `ad_bypass` 导出特性、Web H5 广告和移动端 AdMob Provider。
class_name AdService
extends RefCounted

signal rewarded_ad_started(placement: String)
signal rewarded_ad_completed(placement: String)
signal rewarded_ad_failed(placement: String, reason: String)

const DebugAdProviderScript := preload("res://scripts/ads/debug_ad_provider.gd")
const AdmobProviderScript := preload("res://scripts/ads/admob_provider.gd")
const WebAdProviderScript := preload("res://scripts/ads/web_ad_provider.gd")

const PLACEMENT_PROP_HINT := "prop_hint"
const PLACEMENT_PROP_UNDO := "prop_undo"
const PLACEMENT_EXTRA_STEPS := "extra_steps"

var game: Node
var debug_provider: RefCounted
var admob_provider: RefCounted
var web_provider: RefCounted
var showing_rewarded_ad := false


func _init(game_scene: Node) -> void:
	game = game_scene
	debug_provider = DebugAdProviderScript.new(game_scene)
	admob_provider = AdmobProviderScript.new(game_scene)
	admob_provider.rewarded_ad_completed.connect(_on_provider_rewarded_ad_completed)
	admob_provider.rewarded_ad_failed.connect(_on_provider_rewarded_ad_failed)
	web_provider = WebAdProviderScript.new(game_scene)
	web_provider.rewarded_ad_completed.connect(_on_provider_rewarded_ad_completed)
	web_provider.rewarded_ad_failed.connect(_on_provider_rewarded_ad_failed)


## 当前是否可以展示指定激励广告。
func can_show_rewarded(placement: String) -> bool:
	if showing_rewarded_ad:
		return false
	if debug_provider.is_available():
		return true
	return _real_rewarded_provider_available(placement)


## 请求播放激励广告。奖励只通过 completed 信号发放，避免 SDK 直接改游戏状态。
func show_rewarded(placement: String) -> bool:
	if not can_show_rewarded(placement):
		return false
	showing_rewarded_ad = true
	rewarded_ad_started.emit(placement)
	if debug_provider.is_available():
		return debug_provider.show_rewarded(placement)
	return _show_real_rewarded(placement)


## 测试入口：直接设置编辑器后门状态。
func set_editor_bypass_enabled(enabled: bool) -> void:
	debug_provider.set_editor_bypass_enabled(enabled)


## 非正式包后门的异步完成入口，由 DebugAdProvider 下一帧调用。
func complete_debug_rewarded_ad(placement: String) -> void:
	if not showing_rewarded_ad:
		return
	showing_rewarded_ad = false
	rewarded_ad_completed.emit(placement)


## 真实 SDK 播放失败时统一走这里，调用方不发奖励。
func _fail_rewarded_ad(placement: String, reason: String) -> bool:
	showing_rewarded_ad = false
	rewarded_ad_failed.emit(placement, reason)
	return false


func _real_rewarded_provider_available(_placement: String) -> bool:
	return (web_provider != null and web_provider.is_available()) \
		or (admob_provider != null and admob_provider.is_available())


func _show_real_rewarded(placement: String) -> bool:
	if web_provider != null and web_provider.show_rewarded(placement):
		return true
	if admob_provider != null and admob_provider.show_rewarded(placement):
		return true
	return _fail_rewarded_ad(placement, "rewarded provider is not configured")


func _on_provider_rewarded_ad_completed(placement: String) -> void:
	if not showing_rewarded_ad:
		return
	showing_rewarded_ad = false
	rewarded_ad_completed.emit(placement)


func _on_provider_rewarded_ad_failed(placement: String, reason: String) -> void:
	if not showing_rewarded_ad:
		return
	showing_rewarded_ad = false
	rewarded_ad_failed.emit(placement, reason)
