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
	second.queue_free()

	_write_tampered_inventory()
	var third: Node = load("res://scenes/main.tscn").instantiate()
	third.user_settings_path = TEMP_SETTINGS_PATH
	root.add_child(third)
	third._ready()
	_assert(third.prop_system.count(third.PropSystemScript.PROP_HINT) == 1, "tampered hint inventory falls back to default")
	_assert(third.prop_system.count(third.PropSystemScript.PROP_UNDO) == 1, "tampered undo inventory falls back to default")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
	print("PROP_INVENTORY_PERSISTENCE_SMOKE_PASS")
	quit(0)


func _write_tampered_inventory() -> void:
	var config := ConfigFile.new()
	config.set_value("props", "hint", 99)
	config.set_value("props", "undo", 99)
	config.set_value("props", "salt", "edited")
	config.set_value("props", "checksum", "edited")
	config.save(TEMP_SETTINGS_PATH)


func _assert(condition: bool, label: String) -> void:
	if not condition:
		push_error("Prop inventory persistence smoke failed: " + label)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_SETTINGS_PATH))
		quit(1)
