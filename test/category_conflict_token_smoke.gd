extends SceneTree


func _initialize() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	for i in range(80):
		var selection: Dictionary = scene._select_categories_for_game()
		_assert(selection.size() == scene.CATEGORIES_PER_GAME, "default pool still selects a full game")
		_assert(_selection_has_no_cross_category_conflict_tokens(scene, selection), "default pool avoids cross-category token confusion")

	scene.category_pool = {
		"家具": ["桌子", "椅子", "沙发", "书柜", "床头柜", "衣柜", "茶几"],
		"茶具": ["茶壶", "茶盏", "茶盘"],
		"城市": ["北京", "上海", "广州"],
		"职业": ["医生", "教师", "律师"],
		"建筑": ["宫殿", "城墙", "拱桥"],
		"水果": ["苹果", "香蕉", "葡萄"],
		"文具": ["铅笔", "橡皮", "尺子"],
		"宝石": ["翡翠", "玛瑙", "珍珠"],
		"运动": ["足球", "篮球", "网球"],
		"甜点": ["蛋糕", "布丁", "曲奇"],
	}

	for i in range(40):
		var selection: Dictionary = scene._select_categories_for_game()
		_assert(selection.size() == scene.CATEGORIES_PER_GAME, "controlled pool still selects a full game")
		_assert(not (selection.has("家具") and selection.has("茶具")), "furniture and tea set categories do not appear together")

	scene.free()
	print("CATEGORY_CONFLICT_TOKEN_SMOKE_PASS")
	quit(0)


func _selection_has_no_cross_category_conflict_tokens(scene: Node, selection: Dictionary) -> bool:
	var seen_tokens := {}
	for category in selection.keys():
		for word in selection[category]:
			for token in scene._word_conflict_tokens(word):
				if seen_tokens.has(token) and seen_tokens[token] != category:
					return false
				seen_tokens[token] = category
	return true


func _assert(condition: bool, label: String) -> void:
	if not condition:
		push_error("Category conflict token smoke failed: " + label)
		quit(1)
