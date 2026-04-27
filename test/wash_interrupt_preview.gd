extends SceneTree

var scene: Node
var frames := 0


func _initialize() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene._ready()
	scene.menu_active = false
	scene.deck.clear()
	for word in ["苹果", "香蕉", "葡萄"]:
		scene.deck.append(scene._word(word, false))
	scene.draw_stack.clear()
	scene._render()


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2:
		scene._handle_deck_pressed()
		scene._handle_deck_pressed()
		scene._handle_deck_pressed()
	if frames == 3:
		scene._handle_deck_pressed()
	return false
