extends SceneTree


func _initialize() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	scene._ready()

	var total_cards: int = _total_cards(scene)
	_assert(scene.draw_stack.is_empty(), "area 1 starts empty")
	_assert(scene.active_order.is_empty(), "area 3 starts empty")
	_assert(scene.categories.size() == scene.CATEGORIES_PER_GAME, "game randomly selects category subset")
	_assert(_selected_words_are_unique(scene), "one word does not belong to two categories in a game")
	_assert(_selected_categories_have_varied_lengths(scene), "selected categories have varied word counts")
	_assert(scene.steps_left == 120, "initial steps")
	_assert(_board_card_count(scene) == 24, "expanded random board has 24 cards")
	_assert(scene.deck.size() == total_cards - 24, "remaining cards start in deck")
	_assert(_board_has_category(scene), "area 4 can contain category cards")
	_assert(_only_bottom_cards_face_up(scene), "only bottom cards are face up initially")
	_assert(scene._card_text(scene._word("水浒传", false)) == "", "face-down card back has no pattern text")
	_assert(scene._font_size_for_card_text("明清小说\n2/6", "category") < scene._font_size_for_card_text("宝石\n2/6", "category"), "long category names use smaller font")
	_assert(scene._font_size_for_card_text("夏威夷果", "word") < scene._font_size_for_card_text("苹果", "word"), "long word names use smaller font")
	_assert(scene._font_size_for_strip_text("夏威夷果") < scene._font_size_for_strip_text("苹果"), "long strip labels use smaller font")

	_load_controlled_level(scene)

	scene._on_deck_pressed()
	_assert(scene.draw_stack.size() == 1, "draw adds to area 1")
	_assert(scene.deck.size() == 2, "draw removes from deck")
	_assert(scene.steps_left == 119, "draw consumes a step")
	_assert(scene.draw_stack[0]["name"] == "明清小说", "controlled first card is top of draw stack")

	scene.selected = scene._selection_for_draw(0)
	_assert(scene._move_selected_to_empty_category(0), "drag category to empty category slot")
	scene._after_successful_move()
	_assert(scene.active_categories.has("明清小说"), "category moves into area 3")
	_assert(scene.draw_stack.is_empty(), "moving category clears area 1")
	_assert(scene.steps_left == 118, "move consumes a step")

	scene.selected = scene._selection_for_board(1, 2)
	_assert(scene._move_selected_to_active_category("明清小说"), "drag word to active category")
	scene._after_successful_move()
	_assert(scene.active_categories["明清小说"]["collected"].has("水浒传"), "matching word is absorbed")
	_assert(scene.columns[1].size() == 2, "word removed from board column")
	_assert(scene.columns[1][1]["face_up"], "covered card reveals after bottom card moves")

	while scene.deck.size() > 0:
		scene._on_deck_pressed()
	_assert(scene.deck.is_empty(), "deck can be exhausted")
	_assert(scene.draw_stack.size() == 2, "area 1 keeps drawn cards")
	var before_wash_steps: int = scene.steps_left
	scene._on_deck_pressed()
	_assert(scene.deck.size() == 2, "wash returns area 1 to deck")
	_assert(scene.draw_stack.is_empty(), "wash clears area 1")
	_assert(scene.steps_left == before_wash_steps - 1, "wash consumes a step")

	scene.selected = scene._selection_for_board(0, scene.columns[0].size() - 1)
	_assert(not scene._move_selected_to_column(1), "invalid drag target is rejected")
	_assert(scene.columns[0][scene.columns[0].size() - 1]["name"] == "超人", "invalid drag leaves source in place")

	scene.active_categories.clear()
	scene.active_order.clear()
	scene.active_categories["宝石"] = {"collected": []}
	scene.active_categories["收纳"] = {"collected": []}
	scene.active_order.append("宝石")
	scene.active_order.append("收纳")
	var gem_cards: Array = []
	for word in scene.categories["宝石"]:
		gem_cards.append(scene._word(word, true))
	scene._collect_words("宝石", gem_cards)
	_assert(not scene.active_categories.has("宝石"), "completed category disappears")
	_assert(scene.active_order[0] == "", "completed category leaves its slot empty")
	_assert(scene.active_order[1] == "收纳", "later category does not refill left")

	scene.free()
	print("RULE_SMOKE_PASS")
	quit(0)


func _load_controlled_level(scene: Node) -> void:
	scene.categories = {
		"明清小说": ["水浒传", "红楼梦", "西游记", "三国演义", "金瓶梅"],
		"宝石": ["翡翠", "玛瑙", "水晶", "珍珠", "琥珀"],
		"收纳": ["收纳袋", "衣架", "挂钩", "置物架"],
		"英雄": ["钢铁侠", "蝙蝠侠", "超人", "蜘蛛侠", "绿巨人"],
		"坚果": ["夏威夷果", "开心果", "松子", "杏仁"],
	}
	scene.word_to_category.clear()
	for category in scene.categories.keys():
		for word in scene.categories[category]:
			scene.word_to_category[word] = category
	scene.deck = [
		scene._word("水晶", false),
		scene._word("三国演义", false),
		scene._category("明清小说", false),
	]
	scene.draw_stack = []
	scene.columns = [
		[scene._word("衣架", false), scene._word("钢铁侠", false), scene._word("蝙蝠侠", false), scene._word("超人")],
		[scene._word("挂钩", false), scene._word("红楼梦", false), scene._word("水浒传")],
		[scene._word("西游记", false), scene._word("夏威夷果", false), scene._word("开心果", false), scene._word("松子")],
		[scene._category("宝石", false), scene._word("翡翠")],
	]
	scene.active_categories.clear()
	scene.active_order.clear()
	scene.selected.clear()
	scene.steps_left = 120
	scene.game_over = false
	scene.status_text = "controlled test"
	for column in scene.columns:
		for i in range(column.size()):
			column[i]["face_up"] = i == column.size() - 1


func _total_cards(scene: Node) -> int:
	var total: int = 0
	for category in scene.categories.keys():
		total += 1 + scene.categories[category].size()
	return total


func _board_card_count(scene: Node) -> int:
	var count: int = 0
	for column in scene.columns:
		count += column.size()
	return count


func _board_has_category(scene: Node) -> bool:
	for column in scene.columns:
		for card in column:
			if card["type"] == "category":
				return true
	return false


func _only_bottom_cards_face_up(scene: Node) -> bool:
	for column in scene.columns:
		for i in range(column.size()):
			var should_be_face_up: bool = i == column.size() - 1
			if bool(column[i]["face_up"]) != should_be_face_up:
				return false
	return true


func _selected_words_are_unique(scene: Node) -> bool:
	var seen := {}
	for category in scene.categories.keys():
		var words: Array = scene.categories[category]
		if words.size() < 3 or words.size() > 8:
			return false
		for word in words:
			if seen.has(word):
				return false
			seen[word] = category
	return true


func _selected_categories_have_varied_lengths(scene: Node) -> bool:
	var lengths := {}
	for category in scene.categories.keys():
		lengths[scene.categories[category].size()] = true
	return lengths.size() >= 4


func _assert(condition: bool, label: String) -> void:
	if not condition:
		push_error("Rule smoke failed: " + label)
		quit(1)
