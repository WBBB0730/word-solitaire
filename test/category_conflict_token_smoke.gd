extends SceneTree


func _initialize() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	var ok := true
	for i in range(80):
		var selection: Dictionary = scene._select_categories_for_game()
		ok = _assert(selection.size() == scene.CATEGORIES_PER_GAME, "default pool still selects a full game") and ok
		ok = _assert(_selection_has_no_cross_category_conflict_tokens(scene, selection), "default pool avoids cross-category token confusion") and ok

	scene.category_pool = {
		"家具": ["桌子", "椅子", "沙发", "书柜", "床头柜", "衣柜", "茶几", "餐桌"],
		"茶具": ["茶壶", "茶盏", "茶盘", "盖碗", "公道杯", "茶则", "茶夹", "茶针"],
		"城市": ["北京", "上海", "广州", "成都", "杭州", "西安", "南京", "重庆"],
		"职业": ["医生", "教师", "律师", "厨师", "记者", "工程师", "护士", "会计"],
		"建筑": ["宫殿", "城墙", "拱桥", "灯塔", "剧院", "寺庙", "钟楼", "牌坊"],
		"水果": ["苹果", "香蕉", "葡萄", "桃子", "菠萝", "荔枝", "西瓜", "芒果"],
		"文具": ["铅笔", "橡皮", "尺子", "圆珠笔", "钢笔", "笔记本", "修正带", "卷笔刀"],
		"宝石": ["翡翠", "玛瑙", "水晶", "珍珠", "琥珀", "钻石", "蓝宝石", "祖母绿"],
		"球类运动": ["足球", "篮球", "网球", "排球", "乒乓球", "羽毛球", "橄榄球", "高尔夫球"],
		"甜点": ["蛋糕", "布丁", "曲奇", "泡芙", "慕斯", "蛋挞", "马卡龙", "提拉米苏"],
		"朝代": ["秦朝", "唐朝", "宋朝", "明朝", "清朝", "元朝", "隋朝", "晋朝"],
		"颜色": ["红色", "橙色", "黄色", "绿色", "青色", "蓝色", "紫色", "白色"],
		"天气": ["晴天", "暴雨", "彩虹", "台风", "阴天", "多云", "小雨", "大雾"],
		"棋类": ["围棋", "象棋", "军棋", "跳棋", "五子棋", "国际象棋", "飞行棋", "斗兽棋"],
	}

	for i in range(40):
		var selection: Dictionary = scene._select_categories_for_game()
		ok = _assert(selection.size() == scene.CATEGORIES_PER_GAME, "controlled pool still selects a full game") and ok
		ok = _assert(not (selection.has("家具") and selection.has("茶具")), "furniture and tea set categories do not appear together") and ok

	scene.free()
	if not ok:
		quit(1)
		return
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


func _assert(condition: bool, label: String) -> bool:
	if not condition:
		push_error("Category conflict token smoke failed: " + label)
		return false
	return true
