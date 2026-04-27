extends SceneTree

var scene: Node
var frames := 0
var card := {}


func _initialize() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 1:
		_setup_scene()
	if frames == 3:
		scene._reveal_bottom_card(0)
		scene._render()
	return false


func _setup_scene() -> void:
	scene._ready()
	scene.menu_active = false
	card = scene._word("苹果", false)
	scene.deck.clear()
	scene.draw_stack.clear()
	scene.active_categories.clear()
	scene.active_order.clear()
	scene.columns.clear()
	scene.columns.append([card])
	scene.columns.append([])
	scene.columns.append([])
	scene.columns.append([])
	scene._render()
