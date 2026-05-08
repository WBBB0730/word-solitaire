extends SceneTree

const SHELL_PATH := "res://web/shell.html"


func _init() -> void:
	var shell := FileAccess.get_file_as_string(SHELL_PATH)
	var web_provider := FileAccess.get_file_as_string("res://scripts/ads/web_ad_provider.gd")
	_assert(shell.contains("WordSolitaireH5AdsConfig"), "Web shell should expose H5 ad config")
	_assert(shell.contains("WordSolitaireH5AdsState"), "Web shell should track H5 ad script load state")
	_assert(shell.contains("testFallback: false"), "Web shell should not mask Google mock ads with the local fallback by default")
	_assert(shell.contains("h5-ad-overlay"), "Web shell should retain the explicit local fallback overlay")
	_assert(shell.contains("preloadAdBreaks: \"on\""), "Web shell should preload H5 ads before the first rewarded request")
	_assert(shell.contains("onReady"), "Web shell should wait for Google H5 ads to finish preloading")
	_assert(shell.contains("pagead2.googlesyndication.com/pagead/js/adsbygoogle.js"), "Web shell should load Google H5 ads script")
	_assert(shell.contains("data-adbreak-test"), "Web shell should enable Google H5 test mode by default")
	_assert(shell.contains("adsScript.onload"), "Web bridge should wait for the H5 ads script to load")
	_assert(shell.contains("window.WordSolitaireWebAds"), "Web shell should expose the Godot JS bridge")
	_assert(shell.contains("Object.freeze(bridge)"), "Web shell should freeze the exposed ad bridge")
	_assert(shell.contains("type: \"reward\""), "Web shell should request rewarded ad placements")
	_assert(shell.contains("requestId"), "Web shell should require one-shot rewarded request ids")
	_assert(shell.contains("showAdFn"), "Web rewarded ads should use Google's rewarded show function")
	_assert(not shell.contains("showRewardPrompt"), "Web rewarded ads should not show an extra opt-in prompt")
	_assert(shell.contains("adViewed"), "Web shell should only reward viewed ads")
	_assert(shell.contains("adDismissed"), "Web shell should handle dismissed rewarded ads")
	_assert(shell.contains("adBreakDone"), "Web shell should log Google placement status for debugging")
	_assert(web_provider.contains("pending_request_id"), "Web provider should track the current rewarded request id")
	_assert(web_provider.contains("requestRewarded(placement, pending_request_id"), "Web provider should send request id to JS bridge")
	_assert(not shell.contains("crazygames"), "Web shell should not depend on CrazyGames for Vercel builds")
	_assert(not shell.contains("CrazyGames"), "Web shell should not depend on CrazyGames for Vercel builds")
	quit()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
