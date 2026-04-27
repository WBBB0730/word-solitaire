extends SceneTree

var scene: Node
var draw_count := 3
var frame := 0
var draws_done := 0


func _initialize() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene._ready()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--draw-count="):
			draw_count = int(arg.get_slice("=", 1))


func _process(_delta: float) -> bool:
	frame += 1
	if frame >= 2 and draws_done < draw_count and not scene.deck_animation_busy:
		scene._on_deck_pressed()
		draws_done += 1
	return false
