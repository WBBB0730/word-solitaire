extends SceneTree


func _initialize() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	scene._ready()

	scene.categories = {
		"测试类别": ["词01", "词02", "词03", "词04"],
		"备用类别": ["词05", "词06", "词07", "词08"],
	}
	scene.word_to_category.clear()
	for category in scene.categories.keys():
		for word in scene.categories[category]:
			scene.word_to_category[word] = category
	scene.next_card_id = 1

	var cards: Array = []
	for i in range(scene.BOARD_COLUMN_COUNT * scene.BOARD_CARDS_PER_COLUMN):
		cards.append(scene._word("词" + str((i % 8) + 1).pad_zeros(2), false))
	cards.append(scene._category("测试类别", false))
	cards.append(scene._category("备用类别", false))

	scene._deal_board_and_deck(cards)

	_assert(_bottom_visible_has_category(scene), "visible bottom cards include a category after guarded deal")
	_assert(_bottom_visible_word_count(scene) >= 2, "visible bottom cards include at least two words after category guard")
	_assert(_only_bottom_cards_face_up(scene), "only bottom cards are face up after guarded deal")
	_assert(scene.deck.size() == 2, "guarded deal preserves deck size")
	_assert(_total_card_count(scene) == cards.size(), "guarded deal preserves total card count")

	cards.clear()
	for i in range(scene.BOARD_COLUMN_COUNT * scene.BOARD_CARDS_PER_COLUMN):
		if i >= 20:
			cards.append(scene._category("测试类别", false))
		else:
			cards.append(scene._word("词" + str((i % 8) + 1).pad_zeros(2), false))
	cards.append(scene._word("词01", false))
	cards.append(scene._word("词02", false))

	scene._deal_board_and_deck(cards)
	_assert(_bottom_visible_has_category(scene), "visible bottom cards still keep a category after word guard")
	_assert(_bottom_visible_word_count(scene) >= 2, "visible bottom cards include at least two words after word guard")
	_assert(_only_bottom_cards_face_up(scene), "only bottom cards are face up after word guard")
	_assert(scene.deck.size() == 2, "word guard preserves deck size")
	_assert(_total_card_count(scene) == cards.size(), "word guard preserves total card count")

	scene.free()
	print("INITIAL_VISIBLE_CATEGORY_SMOKE_PASS")
	quit(0)


func _bottom_visible_has_category(scene: Node) -> bool:
	for column in scene.columns:
		if not column.is_empty() and column[column.size() - 1]["type"] == "category":
			return true
	return false


func _bottom_visible_word_count(scene: Node) -> int:
	var count := 0
	for column in scene.columns:
		if not column.is_empty() and column[column.size() - 1]["type"] == "word":
			count += 1
	return count


func _only_bottom_cards_face_up(scene: Node) -> bool:
	for column in scene.columns:
		for i in range(column.size()):
			if bool(column[i]["face_up"]) != (i == column.size() - 1):
				return false
	return true


func _total_card_count(scene: Node) -> int:
	var total: int = scene.deck.size()
	for column in scene.columns:
		total += column.size()
	return total


func _assert(condition: bool, label: String) -> void:
	if not condition:
		push_error("Initial visible category smoke failed: " + label)
		quit(1)
