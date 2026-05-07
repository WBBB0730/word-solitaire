extends SceneTree

const TEMP_SETTINGS_PATH := "user://prop_inventory_persistence_smoke.cfg"


func _initialize() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
	var first: Node = load("res://scenes/main.tscn").instantiate()
	first.user_settings_path = TEMP_SETTINGS_PATH
	root.add_child(first)
	first._ready()
	first.prop_system.set_count(first.PropSystemScript.PROP_HINT, 7)
	first.prop_system.set_count(first.PropSystemScript.PROP_UNDO, 8)
	first._save_user_settings()
	first.queue_free()

	var second: Node = load("res://scenes/main.tscn").instantiate()
	second.user_settings_path = TEMP_SETTINGS_PATH
	root.add_child(second)
	second._ready()
	_assert(second.prop_system.count(second.PropSystemScript.PROP_HINT) == 7, "hint inventory is persisted")
	_assert(second.prop_system.count(second.PropSystemScript.PROP_UNDO) == 8, "undo inventory is persisted")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
	print("PROP_INVENTORY_PERSISTENCE_SMOKE_PASS")
	quit(0)


func _assert(condition: bool, label: String) -> void:
	if not condition:
		push_error("Prop inventory persistence smoke failed: " + label)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
		quit(1)
