extends SceneTree

var scene: Node
var frames := 0


func _initialize() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 1:
		scene._ready()
		scene.menu_active = false
		scene.deck.clear()
		scene.draw_stack = [
			scene._word("苹果", true),
			scene._word("香蕉", true),
			scene._word("葡萄", true),
			scene._word("桃子", true),
		]
		scene.previous_card_positions.clear()
		scene._render()
	if frames == 4:
		for i in range(1, 4):
			scene.previous_card_positions[scene.draw_stack[i]["id"]] = scene._draw_card_position_for_size(i, 4)
		scene.selected = scene._selection_for_draw(3)
		scene._remove_selected_from_source()
		scene._render()
	return false
