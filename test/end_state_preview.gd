extends SceneTree

var scene: Node
var state := "win"
var frames := 0
var configured := false


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--state="):
			state = arg.get_slice("=", 1)


func _process(_delta: float) -> bool:
	if not configured:
		configured = true
		scene = _find_game_scene(root)
		if scene == null:
			scene = load("res://scenes/main.tscn").instantiate()
			root.add_child(scene)
		_configure_scene()
		return false
	frames += 1
	if frames > 2:
		quit(0)
	return false


func _configure_scene() -> void:
	scene.menu_active = false
	scene.next_card_id = 1
	if state == "win":
		_load_win_state()
	elif state == "deadlock":
		_load_deadlock_state()
	else:
		_load_steps_failure_state()
	scene._check_end_state()
	scene._render()


func _find_game_scene(node: Node) -> Node:
	if node.has_method("_check_end_state") and node.has_method("_render"):
		return node
	for child in node.get_children():
		var found := _find_game_scene(child)
		if found != null:
			return found
	return null


func _load_win_state() -> void:
	scene.deck.clear()
	scene.draw_stack.clear()
	scene.columns = [[], [], [], []]
	scene.active_categories.clear()
	scene.active_order.clear()
	scene.steps_left = 37
	scene.game_over = false
	scene.status_text = "preview win"


func _load_steps_failure_state() -> void:
	scene.categories = {"水果": ["苹果", "香蕉", "葡萄"]}
	scene.word_to_category = {"苹果": "水果", "香蕉": "水果", "葡萄": "水果"}
	scene.deck = [scene._word("苹果", false)]
	scene.draw_stack.clear()
	scene.columns = [[], [], [], []]
	scene.active_categories.clear()
	scene.active_order.clear()
	scene.steps_left = 0
	scene.game_over = false
	scene.status_text = "preview steps failure"


func _load_deadlock_state() -> void:
	scene.categories = {
		"水果": ["苹果", "香蕉", "葡萄"],
		"宝石": ["翡翠", "玛瑙", "珍珠"],
		"文具": ["铅笔", "橡皮", "尺子"],
		"天气": ["晴天", "暴雨", "彩虹"],
	}
	scene.word_to_category.clear()
	for category in scene.categories.keys():
		for word in scene.categories[category]:
			scene.word_to_category[word] = category
	scene.deck.clear()
	scene.draw_stack.clear()
	scene.columns = [
		[scene._category("水果")],
		[scene._category("宝石")],
		[scene._category("文具")],
		[scene._category("天气")],
	]
	scene.active_categories.clear()
	scene.active_order.clear()
	for category in scene.categories.keys():
		scene.active_categories[category] = {"collected": []}
		scene.active_order.append(category)
	scene.steps_left = 12
	scene.game_over = false
	scene.status_text = "preview deadlock"
