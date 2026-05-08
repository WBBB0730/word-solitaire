## Web 激励广告 Provider。
##
## 第一版接 Google H5 Ad Placement API。`web/shell.html` 默认开启测试模式，
## 可以在 Vercel 等自托管 Web 环境体验完整激励广告回调流程。
class_name WebAdProvider
extends RefCounted

signal rewarded_ad_completed(placement: String)
signal rewarded_ad_failed(placement: String, reason: String)

var game: Node
var web_ads
var ad_started_callback
var ad_finished_callback
var ad_error_callback
var pending_placement := ""
var pending_request_id := ""


func _init(game_scene: Node) -> void:
	game = game_scene
	if OS.has_feature("web"):
		_setup_bridge()


## Web shell 中广告 bridge 当前是否可请求激励广告。
func is_available() -> bool:
	if not OS.has_feature("web") or web_ads == null:
		return false
	var available = JavaScriptBridge.eval("""
		!!(
			window.WordSolitaireWebAds &&
			window.WordSolitaireWebAds.isAvailable &&
			window.WordSolitaireWebAds.isAvailable()
		);
	""")
	return bool(available)


## 请求播放 Web 激励广告。奖励只在 JS bridge 的完成回调后发放。
func show_rewarded(placement: String) -> bool:
	if not is_available() or pending_placement != "":
		return false
	pending_placement = placement
	pending_request_id = _new_request_id(placement)
	web_ads.requestRewarded(placement, pending_request_id, ad_started_callback, ad_finished_callback, ad_error_callback)
	return true


func _setup_bridge() -> void:
	web_ads = JavaScriptBridge.get_interface("WordSolitaireWebAds")
	if web_ads == null:
		return
	ad_started_callback = JavaScriptBridge.create_callback(_on_ad_started)
	ad_finished_callback = JavaScriptBridge.create_callback(_on_ad_finished)
	ad_error_callback = JavaScriptBridge.create_callback(_on_ad_error)


func _on_ad_started(_args: Array) -> void:
	pass


func _on_ad_finished(args: Array) -> void:
	var placement := _read_callback_placement(args)
	var request_id := _read_callback_request_id(args)
	if placement == "" or placement != pending_placement or request_id != pending_request_id:
		return
	pending_placement = ""
	pending_request_id = ""
	rewarded_ad_completed.emit(placement)


func _on_ad_error(args: Array) -> void:
	var placement := _read_callback_placement(args)
	var request_id := _read_callback_request_id(args)
	if placement == "" or placement != pending_placement or request_id != pending_request_id:
		return
	var reason := "web rewarded ad failed"
	if args.size() >= 3:
		reason = str(args[2])
	pending_placement = ""
	pending_request_id = ""
	rewarded_ad_failed.emit(placement, reason)


func _read_callback_placement(args: Array) -> String:
	if args.is_empty():
		return ""
	return str(args[0])


func _read_callback_request_id(args: Array) -> String:
	if args.size() < 2:
		return ""
	return str(args[1])


func _new_request_id(placement: String) -> String:
	return "%s:%d:%d" % [placement, Time.get_ticks_usec(), randi()]
