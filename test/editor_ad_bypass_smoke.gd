extends SceneTree

var scene: Node


func _initialize() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene._ready()
	_assert(scene.ad_service.can_show_rewarded(scene.AdServiceScript.PLACEMENT_PROP_HINT), "editor run enables ad bypass by default")
	print("EDITOR_AD_BYPASS_SMOKE_PASS")
	quit(0)


func _assert(condition: bool, label: String) -> void:
	if not condition:
		push_error("Editor ad bypass smoke failed: " + label)
		quit(1)
