extends SceneTree

var scene: Node
var frames := 0
var loaded := false


func _initialize() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	scene._ready()


func _process(_delta: float) -> bool:
	frames += 1
	if not loaded:
		loaded = true
		_load_font_preview_level()
		return false
	if frames > 2:
		quit(0)
	return false


func _load_font_preview_level() -> void:
	scene.categories = {
		"明清小说": ["水浒传", "红楼梦", "西游记", "三国演义", "金瓶梅", "儒林外史"],
		"水果": ["苹果", "香蕉", "葡萄"],
	}
	scene.word_to_category.clear()
	for category in scene.categories.keys():
		for word in scene.categories[category]:
			scene.word_to_category[word] = category
	scene.deck.clear()
	scene.draw_stack.clear()
	scene.columns = [
		[scene._word("夏威夷果")],
		[scene._word("苹果")],
		[],
		[],
	]
	scene.active_categories.clear()
	scene.active_order.clear()
	scene.active_categories["明清小说"] = {"collected": ["水浒传", "红楼梦"]}
	scene.active_categories["水果"] = {"collected": ["苹果"]}
	scene.active_order.append("明清小说")
	scene.active_order.append("水果")
	scene.selected.clear()
	scene.steps_left = 120
	scene.game_over = false
	scene.status_text = "font preview"
	scene.previous_card_positions.clear()
	scene._render()
