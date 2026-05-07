extends SceneTree

var scene: Node


func _initialize() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene._ready()
	_send_cheat_sequence()
	_assert(scene.ad_service.can_show_rewarded(scene.AdServiceScript.PLACEMENT_PROP_HINT), "editor cheat enables ad bypass")
	_send_cheat_sequence()
	_assert(not scene.ad_service.can_show_rewarded(scene.AdServiceScript.PLACEMENT_PROP_HINT), "editor cheat toggles ad bypass off")
	print("AD_CHEAT_SMOKE_PASS")
	quit(0)


func _send_cheat_sequence() -> void:
	for keycode in scene.AD_CHEAT_SEQUENCE:
		var event := InputEventKey.new()
		event.keycode = keycode
		event.pressed = true
		scene._handle_ad_cheat_input(event)


func _assert(condition: bool, label: String) -> void:
	if not condition:
		push_error("Ad cheat smoke failed: " + label)
		quit(1)
