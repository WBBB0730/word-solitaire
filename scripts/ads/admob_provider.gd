## AdMob 激励广告 Provider。
##
## 只在 Android/iOS 运行时动态创建插件节点；桌面、Web 和编辑器继续走
## DebugAdProvider，避免没有原生 singleton 时产生无效调用。
class_name AdmobProvider
extends RefCounted

signal rewarded_ad_completed(placement: String)
signal rewarded_ad_failed(placement: String, reason: String)

const AdmobScript := preload("res://addons/AdmobPlugin/Admob.gd")

const DEFAULT_IS_REAL := false
const DEFAULT_ANDROID_APP_ID := "ca-app-pub-3940256099942544~3347511713"
const DEFAULT_ANDROID_REWARDED_ID := "ca-app-pub-3940256099942544/5224354917"
const DEFAULT_IOS_APP_ID := "ca-app-pub-3940256099942544~1458002511"
const DEFAULT_IOS_REWARDED_ID := "ca-app-pub-3940256099942544/1712485313"

var game: Node
var admob: Node
var initialized := false
var loading_rewarded := false
var loaded_rewarded_ad_id := ""
var pending_placement := ""
var showing_rewarded := false
var current_rewarded_ad_id := ""
var current_reward_earned := false


func _init(game_scene: Node) -> void:
	game = game_scene
	if _is_supported_platform():
		_create_admob_node()


## 当前平台是否可以接入原生 AdMob SDK。
func is_available() -> bool:
	return admob != null


## 播放激励广告；如广告尚未加载，则先加载，等 loaded 回调后立即展示。
func show_rewarded(placement: String) -> bool:
	if not is_available() or pending_placement != "":
		return false
	pending_placement = placement
	if loaded_rewarded_ad_id != "":
		_show_loaded_rewarded()
	else:
		_load_rewarded()
	return true


func _is_supported_platform() -> bool:
	var os_name := OS.get_name()
	var mobile_platform := OS.has_feature("android") or OS.has_feature("ios") or os_name == "Android" or os_name == "iOS"
	return mobile_platform and Engine.has_singleton("AdmobPlugin")


func _create_admob_node() -> void:
	if game == null:
		return
	admob = AdmobScript.new()
	admob.name = "Admob"
	_apply_admob_settings()
	_connect_admob_signals()
	game.add_child(admob)
	# 等插件节点 _ready() 完成 singleton 绑定后再初始化 SDK。
	admob.call_deferred("initialize")


func _apply_admob_settings() -> void:
	var is_real := bool(ProjectSettings.get_setting("admob/is_real", DEFAULT_IS_REAL))
	admob.is_real = is_real
	admob.android_debug_application_id = str(ProjectSettings.get_setting("admob/android_debug_application_id", DEFAULT_ANDROID_APP_ID))
	admob.android_real_application_id = str(ProjectSettings.get_setting("admob/android_real_application_id", DEFAULT_ANDROID_APP_ID))
	admob.android_debug_rewarded_id = str(ProjectSettings.get_setting("admob/android_debug_rewarded_id", DEFAULT_ANDROID_REWARDED_ID))
	admob.android_real_rewarded_id = str(ProjectSettings.get_setting("admob/android_real_rewarded_id", DEFAULT_ANDROID_REWARDED_ID))
	admob.ios_debug_application_id = str(ProjectSettings.get_setting("admob/ios_debug_application_id", DEFAULT_IOS_APP_ID))
	admob.ios_real_application_id = str(ProjectSettings.get_setting("admob/ios_real_application_id", DEFAULT_IOS_APP_ID))
	admob.ios_debug_rewarded_id = str(ProjectSettings.get_setting("admob/ios_debug_rewarded_id", DEFAULT_IOS_REWARDED_ID))
	admob.ios_real_rewarded_id = str(ProjectSettings.get_setting("admob/ios_real_rewarded_id", DEFAULT_IOS_REWARDED_ID))


func _connect_admob_signals() -> void:
	admob.initialization_completed.connect(_on_initialization_completed)
	admob.rewarded_ad_loaded.connect(_on_rewarded_ad_loaded)
	admob.rewarded_ad_failed_to_load.connect(_on_rewarded_ad_failed_to_load)
	admob.rewarded_ad_failed_to_show_full_screen_content.connect(_on_rewarded_ad_failed_to_show)
	admob.rewarded_ad_dismissed_full_screen_content.connect(_on_rewarded_ad_dismissed)
	admob.rewarded_ad_user_earned_reward.connect(_on_rewarded_ad_user_earned_reward)


func _on_initialization_completed(_status_data: InitializationStatus) -> void:
	initialized = true
	_load_rewarded()


func _load_rewarded() -> void:
	if admob == null or not initialized or loading_rewarded or loaded_rewarded_ad_id != "":
		return
	loading_rewarded = true
	admob.load_rewarded_ad()


func _show_loaded_rewarded() -> void:
	if admob == null or loaded_rewarded_ad_id == "":
		_fail_pending_rewarded("rewarded ad is not loaded")
		return
	showing_rewarded = true
	current_reward_earned = false
	current_rewarded_ad_id = loaded_rewarded_ad_id
	loaded_rewarded_ad_id = ""
	admob.show_rewarded_ad(current_rewarded_ad_id)


func _on_rewarded_ad_loaded(ad_info: AdInfo, _response_info: ResponseInfo) -> void:
	loading_rewarded = false
	loaded_rewarded_ad_id = ad_info.get_ad_id()
	if pending_placement != "" and not showing_rewarded:
		_show_loaded_rewarded()


func _on_rewarded_ad_failed_to_load(_ad_info: AdInfo, error_data: LoadAdError) -> void:
	loading_rewarded = false
	if pending_placement != "":
		_fail_pending_rewarded(_read_error_message(error_data, "rewarded ad failed to load"))


func _on_rewarded_ad_failed_to_show(_ad_info: AdInfo, error_data: AdError) -> void:
	_fail_pending_rewarded(_read_error_message(error_data, "rewarded ad failed to show"))
	_load_rewarded()


func _on_rewarded_ad_user_earned_reward(_ad_info: AdInfo, _reward_data: RewardItem) -> void:
	# 只记录奖励已达成；等关闭回调后再恢复游戏输入。
	current_reward_earned = true


func _on_rewarded_ad_dismissed(_ad_info: AdInfo) -> void:
	var placement := pending_placement
	var reward_earned := current_reward_earned
	_clear_current_rewarded()
	if placement == "":
		_load_rewarded()
		return
	if reward_earned:
		pending_placement = ""
		rewarded_ad_completed.emit(placement)
	else:
		pending_placement = ""
		rewarded_ad_failed.emit(placement, "rewarded ad dismissed before reward")
	_load_rewarded()


func _fail_pending_rewarded(reason: String) -> void:
	var placement := pending_placement
	_clear_current_rewarded()
	pending_placement = ""
	if placement != "":
		rewarded_ad_failed.emit(placement, reason)


func _clear_current_rewarded() -> void:
	showing_rewarded = false
	current_rewarded_ad_id = ""
	current_reward_earned = false


func _read_error_message(error_data: Object, fallback: String) -> String:
	if error_data != null and error_data.has_method("get_message"):
		var message = error_data.get_message()
		if not message.is_empty():
			return message
	return fallback
