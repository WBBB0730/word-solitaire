extends Control


func _ready() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	_load_complete_group_demo(scene)


func _load_complete_group_demo(scene: Node) -> void:
	scene.categories = {
		"水果": ["苹果", "香蕉", "葡萄"],
		"文具": ["铅笔", "橡皮", "尺子"],
		"宝石": ["珍珠", "翡翠", "玛瑙"],
	}
	scene.next_card_id = 1
	scene.word_to_category.clear()
	for category in scene.categories.keys():
		for word in scene.categories[category]:
			scene.word_to_category[word] = category
	scene.deck.clear()
	scene.draw_stack.clear()
	scene.columns = [
		[scene._word("苹果"), scene._word("香蕉"), scene._word("葡萄"), scene._category("水果")],
		[scene._word("铅笔"), scene._word("橡皮")],
		[scene._category("文具")],
		[scene._word("珍珠"), scene._word("翡翠")],
	]
	scene.active_categories.clear()
	scene.active_order.clear()
	scene.selected.clear()
	scene.menu_active = false
	scene.game_over = false
	scene.steps_left = 20
	scene.status_text = "把水果整组拖到上方黄色空位"
	scene.previous_card_positions.clear()
	scene._clear_transient_interaction_state(false)
	scene._render()
