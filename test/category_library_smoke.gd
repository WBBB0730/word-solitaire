extends SceneTree

const CategoryLibraryScript := preload("res://scripts/category_library.gd")

const REQUIRED_CONFLICT_PAIRS := [
	["颜色", "流行色"],
	["包装用品", "快递用品"],
	["安全用品", "消防器材"],
	["旅游用品", "露营用品"],
	["机场设施", "飞机部件"],
	["网络术语", "软件工具"],
	["宝石", "矿物"],
	["感官", "声音"],
	["节日", "民俗活动"],
	["棋类", "桌游道具"],
	["职业", "公司部门"],
	["医院科室", "常见病症"],
	["家具", "床上用品"],
	["饮品", "饮料包装"],
	["古代官职", "历史事件"],
]


func _initialize() -> void:
	var pool: Dictionary = CategoryLibraryScript.get_category_pool()
	var conflict_groups: Array = CategoryLibraryScript.get_category_conflict_groups()
	var ok := true
	ok = _assert(pool.size() >= 200, "category pool should contain at least 200 categories") and ok
	ok = _assert(_all_categories_have_minimum_source_words(pool), "every source category should contain at least 3 words") and ok
	ok = _assert(_all_conflict_group_categories_exist(pool, conflict_groups), "all conflict groups should point to existing categories") and ok
	ok = _assert(_duplicate_words_are_conflict_grouped(pool, conflict_groups), "duplicate source words should only appear across conflict-grouped categories") and ok
	ok = _assert(_required_conflict_pairs_are_grouped(conflict_groups), "important related category pairs should be directly grouped") and ok
	ok = _assert(_random_selection_respects_manual_groups_and_lengths(), "random selections should respect conflict groups and 3-8 length slots") and ok
	if not ok:
		quit(1)
		return
	print("CATEGORY_LIBRARY_SMOKE_PASS")
	quit(0)


func _all_categories_have_minimum_source_words(pool: Dictionary) -> bool:
	for category in pool.keys():
		var count: int = pool[category].size()
		if count < 3:
			push_error("Invalid word count: " + category + " has " + str(count))
			return false
	return true


func _duplicate_words_are_conflict_grouped(pool: Dictionary, conflict_groups: Array) -> bool:
	var seen_by_word := {}
	for category in pool.keys():
		var words_in_category := {}
		for word in pool[category]:
			if words_in_category.has(word):
				push_error("Duplicate word inside one category: " + String(category) + " / " + String(word))
				return false
			words_in_category[word] = true
			if not seen_by_word.has(word):
				seen_by_word[word] = []
			for other_category in seen_by_word[word]:
				if not _categories_share_conflict_group(category, other_category, conflict_groups):
					push_error("Duplicate word is not conflict-grouped: " + String(word) + " in " + String(category) + " and " + String(other_category))
					return false
			seen_by_word[word].append(category)
	return true


func _categories_share_conflict_group(category_a: String, category_b: String, conflict_groups: Array) -> bool:
	if category_a == category_b:
		return true
	for group in conflict_groups:
		if category_a in group and category_b in group:
			return true
	return false


func _all_conflict_group_categories_exist(pool: Dictionary, conflict_groups: Array) -> bool:
	for group in conflict_groups:
		for category in group:
			if not pool.has(category):
				push_error("Conflict group references missing category: " + String(category))
				return false
	return true


func _required_conflict_pairs_are_grouped(conflict_groups: Array) -> bool:
	for pair in REQUIRED_CONFLICT_PAIRS:
		var found := false
		for group in conflict_groups:
			if pair[0] in group and pair[1] in group:
				found = true
				break
		if not found:
			push_error("Required conflict pair is not grouped: " + String(pair[0]) + " / " + String(pair[1]))
			return false
	return true


func _random_selection_respects_manual_groups_and_lengths() -> bool:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	for i in range(100):
		var selection: Dictionary = scene._select_categories_for_game()
		if selection.size() != scene.CATEGORIES_PER_GAME:
			scene.free()
			return false
		if not _selection_has_valid_round_lengths(selection):
			scene.free()
			return false
		if not _selection_has_no_category_name_word_conflicts(selection):
			scene.free()
			return false
		if not _selection_has_no_manual_group_conflicts(selection, scene.category_conflict_groups):
			scene.free()
			return false
	scene.free()
	return true


func _selection_has_no_category_name_word_conflicts(selection: Dictionary) -> bool:
	var category_names := {}
	for category in selection.keys():
		category_names[category] = true
	for category in selection.keys():
		for word in selection[category]:
			if category_names.has(word) and word != category:
				push_error("Selected word matches another category name: " + String(word))
				return false
	return true


func _selection_has_valid_round_lengths(selection: Dictionary) -> bool:
	var lengths := {}
	var seven_count := 0
	var eight_count := 0
	for category in selection.keys():
		var length: int = selection[category].size()
		if length < 3 or length > 8:
			push_error("Selected category has invalid round length: " + String(category) + " " + str(length))
			return false
		lengths[length] = true
		if length == 7:
			seven_count += 1
		if length == 8:
			eight_count += 1
	if lengths.size() < 6:
		push_error("Selected round has too little length variety: " + str(lengths.keys()))
		return false
	if seven_count > 2 or eight_count > 1:
		push_error("Selected round violates long-category caps")
		return false
	return true


func _selection_has_no_manual_group_conflicts(selection: Dictionary, conflict_groups: Array) -> bool:
	for category in selection.keys():
		for group in conflict_groups:
			if not category in group:
				continue
			for other_category in group:
				if other_category != category and selection.has(other_category):
					push_error("Manual conflict group repeated: " + String(category) + " / " + String(other_category))
					return false
	return true


func _assert(condition: bool, label: String) -> bool:
	if not condition:
		push_error("Category library smoke failed: " + label)
		return false
	return true
