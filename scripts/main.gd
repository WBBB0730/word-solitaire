extends Control

const CARD_W := 78.0
const CARD_H := 104.0
const STACK_STEP := 24.0
const COL_GAP := 14.0
const DRAW_Y := 24.0
const CATEGORY_Y := 158.0
const BOARD_Y := 282.0
const MAX_CATEGORY_SLOTS := 4
const STARTING_STEPS := 120
const BOARD_COLUMN_COUNT := 4
const BOARD_CARDS_PER_COLUMN := 6
const CATEGORIES_PER_GAME := 9
const DRAG_THRESHOLD := 8.0
const ANIM_TIME := 0.18
const DRAW_ANIM_TIME := 0.28
const DRAG_CANCEL_ANIM_TIME := 0.16
const CATEGORY_ABSORB_ANIM_TIME := 0.20
const CATEGORY_ABSORB_FINAL_SCALE := 0.36

var category_pool := {
	"明清小说": ["水浒传", "红楼梦", "西游记", "三国演义", "金瓶梅", "儒林外史"],
	"宝石": ["翡翠", "玛瑙", "水晶", "珍珠", "琥珀", "钻石", "蓝宝石", "祖母绿"],
	"收纳": ["收纳袋", "衣架", "挂钩", "置物架"],
	"英雄": ["钢铁侠", "蝙蝠侠", "超人", "蜘蛛侠", "绿巨人", "黑寡妇", "雷神"],
	"坚果": ["夏威夷果", "开心果", "松子", "杏仁"],
	"单位": ["千克", "米", "秒", "升", "安培"],
	"水果": ["苹果", "香蕉", "葡萄", "桃子", "菠萝", "荔枝", "西瓜"],
	"文具": ["铅笔", "橡皮", "尺子"],
	"乐器": ["钢琴", "小提琴", "长笛", "唢呐", "古筝", "琵琶"],
	"天气": ["晴天", "暴雨", "彩虹", "台风"],
	"城市": ["北京", "上海", "广州", "成都", "杭州", "西安"],
	"花卉": ["牡丹", "荷花", "梅花"],
	"饮品": ["绿茶", "咖啡", "豆浆", "牛奶", "橙汁", "可乐", "酸奶", "椰汁"],
	"厨具": ["菜刀", "砧板", "铁锅", "蒸笼"],
	"颜色": ["赤色", "橙色", "黄色", "绿色", "青色", "蓝色", "紫色"],
	"交通工具": ["火车", "轮船", "地铁", "飞机", "单车", "公交车"],
	"家具": ["桌子", "椅子", "沙发", "书柜", "床头柜", "衣柜", "茶几"],
	"运动": ["足球", "篮球", "网球"],
	"朝代": ["秦朝", "汉朝", "唐朝", "宋朝", "明朝", "清朝"],
	"节日": ["春节", "元宵", "端午", "中秋"],
	"山川": ["泰山", "黄山", "长江", "黄河", "西湖", "华山", "珠江", "峨眉山"],
	"星体": ["太阳", "月球", "火星"],
	"职业": ["医生", "教师", "律师", "厨师", "记者", "工程师"],
	"电子产品": ["手机", "电脑", "平板", "相机", "耳机", "手表", "音箱"],
	"服饰": ["衬衫", "外套", "围巾", "皮鞋"],
	"餐具": ["筷子", "饭碗", "盘子", "叉子", "茶杯", "汤匙"],
	"调味品": ["酱油", "食盐", "白糖"],
	"书法工具": ["毛笔", "宣纸", "砚台", "印泥"],
	"棋类": ["围棋", "象棋", "军棋", "跳棋", "五子棋", "国际象棋"],
	"数学": ["加法", "分数", "圆周率", "方程", "坐标", "函数", "几何"],
	"物理量": ["速度", "质量", "温度", "电流"],
	"化学元素": ["氢", "碳", "氧", "铁", "铜", "金"],
	"古诗人": ["李白", "杜甫", "王维", "白居易", "李清照", "苏轼", "辛弃疾", "陆游"],
	"西方作家": ["莎士比亚", "雨果", "托尔斯泰", "海明威"],
	"建筑": ["宫殿", "城墙", "拱桥", "灯塔", "剧院", "寺庙"],
	"甜点": ["蛋糕", "布丁", "曲奇"],
	"蔬菜": ["萝卜", "黄瓜", "番茄", "土豆", "菠菜", "茄子", "白菜"],
	"中药": ["人参", "当归", "枸杞", "薄荷"],
	"戏曲": ["京剧", "昆曲", "越剧", "黄梅戏", "豫剧", "评剧"],
	"办公": ["文件夹", "订书机", "便签", "剪刀", "胶带", "印章", "回形针"],
	"摄影": ["镜头", "快门", "光圈", "三脚架"],
	"园艺": ["花盆", "铲子", "喷壶", "肥料", "种子", "剪枝剪"],
	"茶具": ["茶壶", "茶盏", "茶盘"],
	"航天": ["火箭", "卫星", "轨道", "空间站", "探测器", "宇航服", "返回舱", "月球车"],
	"金融": ["股票", "基金", "债券", "汇率"],
	"音乐术语": ["节拍", "旋律", "和弦", "音阶", "休止符", "调式"],
}

var categories := {}
var word_to_category := {}
var deck: Array = []
var draw_stack: Array = []
var columns: Array = []
var active_categories := {}
var active_order: Array[String] = []
var selected := {}
var steps_left := STARTING_STEPS
var next_card_id := 1
var game_over := false
var status_text := "点击牌堆开始"
var previous_card_positions := {}
var pending_spawn_positions := {}
var pending_draw_animations := {}
var animating_draw_cards := {}
var suppress_next_move_animations := {}
var deck_animation_busy := false
var draw_animation_nodes := {}
var draw_animation_cards := {}
var draw_flights := {}
var drag_candidate := {}
var drag_preview: Control
var drag_offset := Vector2.ZERO
var returning_drag_preview: Control
var absorbing_drag_preview: Control
var pending_absorb_slot := -1
var deck_click_bump := false
var deck_press_queued := false

var bg_color := Color("#a9d78e")
var card_color := Color("#fbfbf4")
var category_color := Color("#ffe08a")
var card_border := Color("#161616")
var back_color := Color("#4d9be8")
var slot_color := Color(1.0, 1.0, 1.0, 0.20)


func _ready() -> void:
	randomize()
	_init_level()
	_render()


func _input(event: InputEvent) -> void:
	if drag_candidate.is_empty():
		return
	if event is InputEventMouseMotion:
		_update_drag(event.position, event.global_position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_finish_drag(event.global_position)


func _process(delta: float) -> void:
	_update_draw_flights(delta)


func _init_level() -> void:
	categories = _select_categories_for_game()
	word_to_category.clear()
	for category in categories.keys():
		for word in categories[category]:
			word_to_category[word] = category

	var all_cards := _build_full_deck()
	all_cards.shuffle()
	_deal_board_and_deck(all_cards)


func _select_categories_for_game() -> Dictionary:
	var best_selection := {}
	var best_variety := -1
	for attempt in range(30):
		var selection := _select_category_candidate()
		var variety := _word_count_variety(selection)
		if selection.size() == CATEGORIES_PER_GAME and variety > best_variety:
			best_selection = selection
			best_variety = variety
		if best_variety >= 4:
			break
	return best_selection


func _select_category_candidate() -> Dictionary:
	var names: Array = category_pool.keys()
	names.shuffle()
	var selected_categories := {}
	var used_words := {}
	var used_lengths := {}
	for category in names:
		if selected_categories.size() >= CATEGORIES_PER_GAME:
			break
		if used_lengths.has(category_pool[category].size()) and used_lengths.size() < 5:
			continue
		if not _category_words_are_available(category, used_words):
			continue
		selected_categories[category] = category_pool[category].duplicate()
		used_lengths[category_pool[category].size()] = true
		for word in category_pool[category]:
			used_words[word] = true
	for category in names:
		if selected_categories.size() >= CATEGORIES_PER_GAME:
			break
		if selected_categories.has(category):
			continue
		if not _category_words_are_available(category, used_words):
			continue
		selected_categories[category] = category_pool[category].duplicate()
		for word in category_pool[category]:
			used_words[word] = true
	return selected_categories


func _word_count_variety(selection: Dictionary) -> int:
	var lengths := {}
	for category in selection.keys():
		lengths[selection[category].size()] = true
	return lengths.size()


func _category_words_are_available(category: String, used_words: Dictionary) -> bool:
	for word in category_pool[category]:
		if used_words.has(word):
			return false
	return true


func _build_full_deck() -> Array:
	var all_cards: Array = []
	for category in categories.keys():
		all_cards.append(_category(category, false))
		for word in categories[category]:
			all_cards.append(_word(word, false))
	return all_cards


func _deal_board_and_deck(all_cards: Array) -> void:
	columns.clear()
	for i in range(BOARD_COLUMN_COUNT):
		columns.append([])

	var board_total: int = min(BOARD_COLUMN_COUNT * BOARD_CARDS_PER_COLUMN, all_cards.size())
	var board_cards: Array = all_cards.slice(0, board_total)
	deck = all_cards.slice(board_total)

	if not _cards_include_category(board_cards):
		_swap_category_from_deck_into_board(board_cards)

	for card in board_cards:
		card["face_up"] = false
	for card in deck:
		card["face_up"] = false

	var cursor: int = 0
	for row in range(BOARD_CARDS_PER_COLUMN):
		for col_idx in range(BOARD_COLUMN_COUNT):
			if cursor >= board_cards.size():
				break
			columns[col_idx].append(board_cards[cursor])
			cursor += 1

	for column in columns:
		if not column.is_empty():
			column[column.size() - 1]["face_up"] = true


func _cards_include_category(cards: Array) -> bool:
	for card in cards:
		if card["type"] == "category":
			return true
	return false


func _swap_category_from_deck_into_board(board_cards: Array) -> void:
	for deck_idx in range(deck.size()):
		var deck_card: Dictionary = deck[deck_idx]
		if deck_card["type"] == "category":
			var board_idx: int = randi_range(0, board_cards.size() - 1)
			deck[deck_idx] = board_cards[board_idx]
			board_cards[board_idx] = deck_card
			return


func _word(card_name: String, face_up := true) -> Dictionary:
	var card := {
		"id": next_card_id,
		"type": "word",
		"name": card_name,
		"category": word_to_category.get(card_name, ""),
		"face_up": face_up,
	}
	next_card_id += 1
	return card


func _category(category_name: String, face_up := true) -> Dictionary:
	var card := {
		"id": next_card_id,
		"type": "category",
		"name": category_name,
		"category": category_name,
		"face_up": face_up,
	}
	next_card_id += 1
	return card


func _render() -> void:
	if not is_inside_tree():
		return
	for child in get_children():
		child.queue_free()
	drag_preview = null

	var next_card_positions := {}

	var bg := ColorRect.new()
	bg.color = bg_color
	bg.position = Vector2.ZERO
	bg.size = get_viewport_rect().size
	add_child(bg)

	_add_label("第1关", Vector2(12, 10), Vector2(72, 22), 17, Color(1, 1, 1, 0.86), false)
	_add_label("剩余步数：" + str(steps_left), Vector2(12, 31), Vector2(116, 20), 13, Color(1, 1, 1, 0.82), false)
	_render_draw_area(next_card_positions)
	_render_deck_area()
	_render_category_area()
	_render_board_area(next_card_positions)

	if game_over:
		_render_overlay()

	previous_card_positions = next_card_positions


func _render_draw_area(next_card_positions: Dictionary) -> void:
	var visible_count = min(3, draw_stack.size())
	for i in range(visible_count):
		var card_index = draw_stack.size() - visible_count + i
		var card: Dictionary = draw_stack[card_index]
		if animating_draw_cards.has(card["id"]):
			continue
		var is_top: bool = card_index == draw_stack.size() - 1
		var pos := _draw_card_position(card_index)
		var is_selected: bool = _selected_has_card(card["id"])
		var btn := _make_card_button(card, is_selected, is_top)
		btn.position = pos
		btn.size = Vector2(CARD_W, CARD_H)
		btn.gui_input.connect(_on_draw_card_gui_input.bind(card_index))
		add_child(btn)
		_animate_card_node(btn, card, pos)
		next_card_positions[card["id"]] = pos


func _render_deck_area() -> void:
	var btn := Button.new()
	btn.position = Vector2(_column_x(3), DRAW_Y)
	btn.size = Vector2(78, 104)
	btn.text = _deck_button_text()
	btn.add_theme_font_size_override("font_size", 17)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_color_override("font_focus_color", Color.WHITE)
	var deck_style := _style(back_color, Color.WHITE, 4, 14)
	btn.add_theme_stylebox_override("normal", deck_style)
	btn.add_theme_stylebox_override("hover", deck_style)
	btn.add_theme_stylebox_override("pressed", deck_style)
	btn.pressed.connect(_on_deck_pressed)
	add_child(btn)
	if deck_click_bump:
		deck_click_bump = false
		btn.pivot_offset = btn.size * 0.5
		btn.scale = Vector2(0.92, 0.92)
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", Vector2.ONE, 0.20)


func _render_category_area() -> void:
	for i in range(MAX_CATEGORY_SLOTS):
		var pos := Vector2(_column_x(i), CATEGORY_Y)
		if i < active_order.size() and active_order[i] != "" and active_categories.has(active_order[i]):
			var category: String = active_order[i]
			var state: Dictionary = active_categories[category]
			var total: int = categories[category].size()
			var count: int = state["collected"].size()
			var text = category + "\n" + str(count) + "/" + str(total)
			var btn := Button.new()
			btn.set_meta("category_slot", i)
			btn.position = pos
			btn.size = Vector2(CARD_W, CARD_H)
			btn.text = text
			btn.disabled = false
			btn.add_theme_font_size_override("font_size", _font_size_for_card_text(text, "category"))
			btn.add_theme_color_override("font_color", Color("#443b32"))
			btn.add_theme_color_override("font_hover_color", Color("#443b32"))
			btn.add_theme_color_override("font_pressed_color", Color("#443b32"))
			btn.add_theme_color_override("font_focus_color", Color("#443b32"))
			var category_style := _style(category_color, card_border, 4, 10)
			btn.add_theme_stylebox_override("normal", category_style)
			btn.add_theme_stylebox_override("hover", category_style)
			btn.add_theme_stylebox_override("pressed", category_style)
			add_child(btn)
		else:
			var slot := Button.new()
			slot.position = pos
			slot.size = Vector2(CARD_W, CARD_H)
			slot.text = "+"
			slot.add_theme_font_size_override("font_size", 30)
			slot.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
			var slot_style := _style(slot_color, Color(1, 1, 1, 0.35), 2, 10)
			slot.add_theme_stylebox_override("normal", slot_style)
			slot.add_theme_stylebox_override("hover", slot_style)
			slot.add_theme_stylebox_override("pressed", slot_style)
			add_child(slot)


func _render_board_area(next_card_positions: Dictionary) -> void:
	for col_idx in range(columns.size()):
		var x := _column_x(col_idx)
		var column: Array = columns[col_idx]
		if column.is_empty():
			var empty := Button.new()
			empty.position = Vector2(x, BOARD_Y)
			empty.size = Vector2(CARD_W, CARD_H)
			empty.text = "+"
			empty.add_theme_font_size_override("font_size", 30)
			empty.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
			var empty_style := _style(slot_color, Color(1, 1, 1, 0.35), 2, 10)
			empty.add_theme_stylebox_override("normal", empty_style)
			empty.add_theme_stylebox_override("hover", empty_style)
			empty.add_theme_stylebox_override("pressed", empty_style)
			add_child(empty)
			continue

		for card_idx in range(column.size()):
			var card: Dictionary = column[card_idx]
			var pos := Vector2(x, BOARD_Y + card_idx * STACK_STEP)
			var is_selected: bool = _selected_has_card(card["id"])
			var selectable: bool = bool(card["face_up"]) and card_idx >= _group_start_index(column)
			var covered_by_next := card_idx < column.size() - 1
			var board_text := "" if covered_by_next and card["face_up"] else _card_text_for_board(column, card_idx)
			var btn := _make_card_button(card, is_selected, selectable, board_text)
			btn.position = pos
			btn.size = Vector2(CARD_W, CARD_H)
			btn.gui_input.connect(_on_board_card_gui_input.bind(col_idx, card_idx))
			add_child(btn)
			_animate_card_node(btn, card, pos)
			next_card_positions[card["id"]] = pos
			if covered_by_next and card["face_up"]:
				_add_card_strip_label(btn, _card_text_for_board(column, card_idx))


func _render_overlay() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.35)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var panel := Panel.new()
	panel.position = Vector2(42, 238)
	panel.size = Vector2(291, 150)
	panel.add_theme_stylebox_override("panel", _style(Color("#fff7dc"), card_border, 4, 14))
	add_child(panel)

	_add_label(status_text, Vector2(60, 268), Vector2(255, 42), 24, Color("#352f2b"), true)
	var restart := Button.new()
	restart.position = Vector2(118, 326)
	restart.size = Vector2(140, 40)
	restart.text = "重新开始"
	restart.add_theme_font_size_override("font_size", 20)
	restart.add_theme_color_override("font_color", Color("#544b4b"))
	restart.add_theme_color_override("font_hover_color", Color("#544b4b"))
	restart.add_theme_color_override("font_pressed_color", Color("#544b4b"))
	restart.add_theme_color_override("font_focus_color", Color("#544b4b"))
	var restart_style := _style(Color("#ffe08a"), card_border, 3, 10)
	restart.add_theme_stylebox_override("normal", restart_style)
	restart.add_theme_stylebox_override("hover", restart_style)
	restart.add_theme_stylebox_override("pressed", restart_style)
	restart.pressed.connect(_on_restart_pressed)
	add_child(restart)


func _make_card_button(card: Dictionary, is_selected: bool, is_clickable: bool, override_text := "") -> Button:
	var btn := Button.new()
	btn.set_meta("card_id", card["id"])
	btn.disabled = game_over or not is_clickable
	btn.text = override_text if override_text != "" else _card_text(card)
	btn.add_theme_font_size_override("font_size", _font_size_for_card_text(btn.text, card["type"]))
	btn.add_theme_color_override("font_color", Color("#544b4b"))
	btn.add_theme_color_override("font_hover_color", Color("#544b4b"))
	btn.add_theme_color_override("font_pressed_color", Color("#544b4b"))
	btn.add_theme_color_override("font_focus_color", Color("#544b4b"))
	btn.add_theme_color_override("font_disabled_color", Color("#544b4b"))

	var fill := category_color if card["type"] == "category" else card_color
	var border := Color("#ef4949") if is_selected else card_border
	if not card["face_up"]:
		fill = back_color
		border = Color.WHITE
	btn.add_theme_stylebox_override("normal", _style(fill, border, 4, 10))
	btn.add_theme_stylebox_override("disabled", _style(fill, border, 4, 10))
	btn.add_theme_stylebox_override("hover", _style(fill, border, 4, 10))
	btn.add_theme_stylebox_override("pressed", _style(fill, border, 4, 10))
	return btn


func _animate_card_node(node: Control, card: Dictionary, target_pos: Vector2) -> void:
	var card_id: int = card["id"]
	var suppress_move := suppress_next_move_animations.has(card_id)
	if suppress_move:
		suppress_next_move_animations.erase(card_id)
	var start_pos = target_pos if suppress_move else pending_spawn_positions.get(card_id, previous_card_positions.get(card_id, target_pos))
	node.pivot_offset = node.size * 0.5
	if start_pos != target_pos:
		node.position = start_pos
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(node, "position", target_pos, ANIM_TIME)
	if pending_spawn_positions.has(card_id):
		var is_draw_animation: bool = pending_draw_animations.has(card_id)
		node.modulate.a = 0.0
		node.scale = Vector2(0.58, 0.58) if is_draw_animation else Vector2(0.92, 0.92)
		node.rotation_degrees = -8.0 if is_draw_animation else 0.0
		var appear := create_tween()
		appear.set_parallel(true)
		appear.set_trans(Tween.TRANS_BACK)
		appear.set_ease(Tween.EASE_OUT)
		appear.tween_property(node, "modulate:a", 1.0, 0.12 if is_draw_animation else ANIM_TIME)
		appear.tween_property(node, "scale", Vector2.ONE, 0.26 if is_draw_animation else ANIM_TIME)
		appear.tween_property(node, "rotation_degrees", 0.0, 0.26 if is_draw_animation else ANIM_TIME)
		pending_spawn_positions.erase(card_id)
		pending_draw_animations.erase(card_id)


func _spawn_draw_card_animation(card: Dictionary) -> void:
	if not is_inside_tree():
		draw_stack.append(card)
		deck_animation_busy = false
		return
	var target_pos := _draw_card_position_for_size(draw_stack.size(), draw_stack.size() + 1)
	var fly_card := _make_card_button(card, false, false)
	fly_card.disabled = true
	fly_card.position = Vector2(_column_x(3), DRAW_Y)
	fly_card.size = Vector2(CARD_W, CARD_H)
	fly_card.pivot_offset = fly_card.size * 0.5
	fly_card.scale = Vector2(0.62, 0.62)
	fly_card.rotation_degrees = -10.0
	fly_card.modulate.a = 0.94
	fly_card.z_index = 120
	add_child(fly_card)
	draw_animation_nodes[card["id"]] = fly_card
	draw_animation_cards[card["id"]] = card
	draw_flights[card["id"]] = {
		"elapsed": 0.0,
		"start": fly_card.position,
		"target": target_pos,
	}


func _update_draw_flights(delta: float) -> void:
	if draw_flights.is_empty():
		return
	var finished: Array[int] = []
	for card_id in draw_flights.keys():
		var flight: Dictionary = draw_flights[card_id]
		var fly_card = draw_animation_nodes.get(card_id)
		if not is_instance_valid(fly_card):
			finished.append(card_id)
			continue
		flight["elapsed"] = float(flight["elapsed"]) + delta
		var t: float = clamp(float(flight["elapsed"]) / DRAW_ANIM_TIME, 0.0, 1.0)
		var eased: float = 1.0 - pow(1.0 - t, 3.0)
		var start: Vector2 = flight["start"]
		var target: Vector2 = flight["target"]
		var arc := Vector2(0, -22.0 * sin(t * PI))
		fly_card.position = start.lerp(target, eased) + arc
		var scale_value: float = lerp(0.62, 1.0, eased)
		fly_card.scale = Vector2(scale_value, scale_value)
		fly_card.rotation_degrees = lerp(-10.0, 0.0, eased)
		if t >= 1.0:
			finished.append(card_id)
	for card_id in finished:
		draw_flights.erase(card_id)
		_finish_draw_card_animation(card_id)


func _finish_draw_card_animation(card_id: int) -> void:
	if draw_animation_cards.has(card_id):
		draw_stack.append(draw_animation_cards[card_id])
	draw_animation_cards.erase(card_id)
	var fly_card = draw_animation_nodes.get(card_id)
	draw_animation_nodes.erase(card_id)
	if is_instance_valid(fly_card):
		fly_card.queue_free()
	deck_animation_busy = false
	_render()


func _card_text(card: Dictionary) -> String:
	if not card["face_up"]:
		return ""
	if card["type"] == "category":
		var total: int = categories.get(card["category"], []).size()
		return card["name"] + "\n0/" + str(total)
	return card["name"]


func _card_text_for_board(column: Array, card_idx: int) -> String:
	var card: Dictionary = column[card_idx]
	if not card["face_up"]:
		return _card_text(card)
	if card["type"] == "category":
		var category: String = card["category"]
		var total: int = categories.get(category, []).size()
		var count := _board_group_word_count(column, card_idx)
		return card["name"] + "\n" + str(count) + "/" + str(total)
	return card["name"]


func _add_card_strip_label(parent: Control, text: String) -> void:
	var backing := Panel.new()
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.position = Vector2(5, 3)
	backing.size = Vector2(CARD_W - 10, STACK_STEP - 6)
	backing.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.72), Color(0, 0, 0, 0), 0, 6))
	parent.add_child(backing)

	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = Vector2(3, 2)
	label.size = Vector2(CARD_W - 6, STACK_STEP - 4)
	label.text = text.replace("\n", " ")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", _font_size_for_strip_text(label.text))
	label.add_theme_color_override("font_color", Color("#544b4b"))
	parent.add_child(label)


func _font_size_for_card_text(text: String, card_type: String) -> int:
	var longest_line := _longest_text_line_length(text)
	if card_type == "category":
		if longest_line >= 6:
			return 12
		if longest_line >= 5:
			return 13
		if longest_line >= 4:
			return 15
		return 16
	if longest_line >= 6:
		return 12
	if longest_line >= 5:
		return 13
	if longest_line >= 4:
		return 15
	return 17


func _font_size_for_strip_text(text: String) -> int:
	var longest_line := _longest_text_line_length(text)
	if longest_line >= 6:
		return 9
	if longest_line >= 5:
		return 10
	if longest_line >= 4:
		return 11
	return 13


func _longest_text_line_length(text: String) -> int:
	var longest := 0
	for line in text.split("\n"):
		longest = max(longest, String(line).strip_edges().length())
	return longest


func _board_group_word_count(column: Array, card_idx: int) -> int:
	if column.is_empty():
		return 0
	var card: Dictionary = column[card_idx]
	var category: String = card["category"]
	var start := card_idx
	while start > 0:
		var previous: Dictionary = column[start - 1]
		if not previous["face_up"] or previous["category"] != category:
			break
		start -= 1
	var end := card_idx
	while end < column.size() - 1:
		var next: Dictionary = column[end + 1]
		if not next["face_up"] or next["category"] != category:
			break
		end += 1
	var count := 0
	for i in range(start, end + 1):
		var grouped_card: Dictionary = column[i]
		if grouped_card["type"] == "word":
			count += 1
	return count


func _deck_button_text() -> String:
	if deck.size() > 0:
		return "牌堆\n剩余" + str(deck.size())
	if draw_stack.size() > 0:
		return "洗牌\n" + str(draw_stack.size()) + "张"
	return "空"


func _add_label(text: String, pos: Vector2, label_size: Vector2, font_size: int, color: Color, center := false, fill := Color(0, 0, 0, 0)) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = label_size
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if fill.a > 0.0:
		var panel := Panel.new()
		panel.position = pos
		panel.size = label_size
		panel.add_theme_stylebox_override("panel", _style(fill, Color(0, 0, 0, 0), 0, 14))
		add_child(panel)
	add_child(label)
	return label


func _style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _column_x(col_idx: int) -> float:
	var total_width := BOARD_COLUMN_COUNT * CARD_W + (BOARD_COLUMN_COUNT - 1) * COL_GAP
	var viewport_width := 375.0
	if is_inside_tree():
		viewport_width = get_viewport_rect().size.x
	var start_x := (viewport_width - total_width) * 0.5
	return start_x + col_idx * (CARD_W + COL_GAP)


func _draw_card_position(card_index: int) -> Vector2:
	return _draw_card_position_for_size(card_index, draw_stack.size())


func _draw_card_position_for_size(card_index: int, stack_size: int) -> Vector2:
	var visible_count: int = min(3, stack_size)
	var first_visible_index: int = stack_size - visible_count
	var visible_offset: int = card_index - first_visible_index
	return Vector2(_column_x(2) - visible_offset * 18.0, DRAW_Y)


func _category_slot_rect(slot_idx: int) -> Rect2:
	return Rect2(Vector2(_column_x(slot_idx), CATEGORY_Y), Vector2(CARD_W, CARD_H))


func _board_column_rect(col_idx: int) -> Rect2:
	var column_height := CARD_H
	if col_idx < columns.size() and not columns[col_idx].is_empty():
		column_height = CARD_H + (columns[col_idx].size() - 1) * STACK_STEP
	return Rect2(Vector2(_column_x(col_idx), BOARD_Y), Vector2(CARD_W, column_height))


func _on_deck_pressed() -> void:
	if not is_inside_tree():
		_handle_deck_pressed()
		return
	if deck_press_queued:
		return
	deck_press_queued = true
	call_deferred("_handle_deck_pressed")


func _handle_deck_pressed() -> void:
	deck_press_queued = false
	if game_over or deck_animation_busy:
		return
	deck_click_bump = true
	selected.clear()
	if deck.size() > 0:
		var card: Dictionary = deck.pop_back()
		card["face_up"] = true
		steps_left -= 1
		status_text = "翻出：" + card["name"]
		_check_end_state()
		if is_inside_tree():
			deck_animation_busy = true
			_render()
			_spawn_draw_card_animation(card)
		else:
			draw_stack.append(card)
		return
	elif draw_stack.size() > 0:
		for card in draw_stack:
			card["face_up"] = false
		deck = draw_stack.duplicate()
		deck.shuffle()
		draw_stack.clear()
		_consume_step("洗牌完成")
		return
	else:
		status_text = "牌堆已空"
		_render()
		return


func _on_draw_card_gui_input(event: InputEvent, card_index: int) -> void:
	if game_over:
		return
	if card_index != draw_stack.size() - 1:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag_candidate(_selection_for_draw(card_index), event.position, event.global_position)
		else:
			_finish_drag(event.global_position)
	elif event is InputEventMouseMotion:
		_update_drag(event.position, event.global_position)


func _on_board_card_gui_input(event: InputEvent, col_idx: int, card_idx: int) -> void:
	if game_over:
		return
	var selection := _selection_for_board(col_idx, card_idx)
	if selection.is_empty():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag_candidate(selection, event.position, event.global_position)
		else:
			_finish_drag(event.global_position)
	elif event is InputEventMouseMotion:
		_update_drag(event.position, event.global_position)


func _begin_drag_candidate(selection_data: Dictionary, local_pos: Vector2, global_pos: Vector2) -> void:
	drag_candidate = selection_data
	drag_candidate["pressed_local"] = local_pos
	drag_candidate["pressed_global"] = global_pos
	drag_candidate["dragging"] = false
	drag_offset = local_pos + Vector2(0, float(selection_data.get("drag_offset_y", 0.0)))


func _update_drag(_local_pos: Vector2, global_pos: Vector2) -> void:
	if drag_candidate.is_empty():
		return
	if not bool(drag_candidate.get("dragging", false)):
		var pressed_global: Vector2 = drag_candidate.get("pressed_global", global_pos)
		if global_pos.distance_to(pressed_global) < DRAG_THRESHOLD:
			return
		drag_candidate["dragging"] = true
		selected = drag_candidate.duplicate()
		selected.erase("pressed_local")
		selected.erase("pressed_global")
		selected.erase("dragging")
		drag_preview = _make_drag_preview(selected.get("cards", []))
		add_child(drag_preview)
		drag_preview.z_index = 100
		_hide_drag_source_cards(selected.get("cards", []))
		_pulse_drag_preview()
	if drag_preview != null:
		drag_preview.global_position = global_pos - drag_offset


func _finish_drag(global_pos: Vector2) -> void:
	if drag_candidate.is_empty():
		return
	var was_dragging := bool(drag_candidate.get("dragging", false))
	if was_dragging:
		selected = drag_candidate.duplicate()
		var return_global_position: Vector2 = selected.get("pressed_global", global_pos) - selected.get("pressed_local", Vector2.ZERO)
		if selected.has("return_position"):
			return_global_position = get_global_transform() * selected["return_position"]
		selected.erase("pressed_local")
		selected.erase("pressed_global")
		selected.erase("dragging")
		selected["return_global_position"] = return_global_position
		_drop_selected_at(global_pos)
	drag_candidate.clear()


func _drop_selected_at(global_pos: Vector2) -> void:
	var local_pos := get_global_transform().affine_inverse() * global_pos
	for i in range(MAX_CATEGORY_SLOTS):
		if _category_slot_rect(i).has_point(local_pos):
			if _category_slot_occupied(i):
				var category: String = active_order[i]
				if _move_selected_to_active_category(category):
					selected["absorb_target_position"] = Vector2(_column_x(i), CATEGORY_Y)
					selected["absorb_target_slot"] = i
					_after_successful_move()
				else:
					_cancel_drag_drop()
			else:
				if _move_selected_to_empty_category(i):
					_after_successful_move()
				else:
					_cancel_drag_drop()
			return
	for col_idx in range(BOARD_COLUMN_COUNT):
		if _board_column_rect(col_idx).has_point(local_pos):
			if _move_selected_to_column(col_idx):
				_after_successful_move()
			else:
				_cancel_drag_drop()
			return
	_cancel_drag_drop()


func _cancel_drag_drop() -> void:
	status_text = "不能放到这里"
	if drag_preview != null and is_instance_valid(drag_preview):
		_animate_drag_cancel()
	else:
		selected.clear()
		_render()


func _animate_drag_cancel() -> void:
	returning_drag_preview = drag_preview
	drag_preview = null
	var target_global: Vector2 = selected.get("return_global_position", returning_drag_preview.global_position)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(returning_drag_preview, "global_position", target_global, DRAG_CANCEL_ANIM_TIME)
	tween.parallel().tween_property(returning_drag_preview, "scale", Vector2(0.98, 0.98), DRAG_CANCEL_ANIM_TIME)
	tween.tween_callback(_finish_drag_cancel_animation)


func _finish_drag_cancel_animation() -> void:
	if is_instance_valid(returning_drag_preview):
		returning_drag_preview.queue_free()
	returning_drag_preview = null
	selected.clear()
	_render()


func _make_drag_preview(cards: Array) -> Control:
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size = Vector2(CARD_W, CARD_H + max(0, cards.size() - 1) * STACK_STEP)
	holder.pivot_offset = holder.size * 0.5
	for i in range(cards.size()):
		var card: Dictionary = cards[i]
		var covered_by_next := i < cards.size() - 1
		var preview_text := "" if covered_by_next and card["face_up"] else _card_text_for_drag_stack(cards, i)
		var button := _make_card_button(card, false, false, preview_text)
		button.disabled = true
		button.position = Vector2(0, i * STACK_STEP)
		button.size = Vector2(CARD_W, CARD_H)
		holder.add_child(button)
		if covered_by_next and card["face_up"]:
			_add_card_strip_label(button, _card_text_for_drag_stack(cards, i))
	return holder


func _card_text_for_drag_stack(cards: Array, card_idx: int) -> String:
	var card: Dictionary = cards[card_idx]
	if not card["face_up"]:
		return _card_text(card)
	if card["type"] == "category":
		var category: String = card["category"]
		var total: int = categories.get(category, []).size()
		var count := 0
		for grouped_card in cards:
			if grouped_card["type"] == "word" and grouped_card["category"] == category:
				count += 1
		return card["name"] + "\n" + str(count) + "/" + str(total)
	return card["name"]


func _hide_drag_source_cards(cards: Array) -> void:
	var card_ids := {}
	for card in cards:
		card_ids[card["id"]] = true
	_hide_drag_source_cards_in_node(self, card_ids)


func _hide_drag_source_cards_in_node(node: Node, card_ids: Dictionary) -> void:
	for child in node.get_children():
		if child == drag_preview:
			continue
		if child is Control and child.has_meta("card_id") and card_ids.has(child.get_meta("card_id")):
			child.visible = false
			continue
		_hide_drag_source_cards_in_node(child, card_ids)


func _pulse_drag_preview() -> void:
	if drag_preview == null:
		return
	drag_preview.scale = Vector2(1.03, 1.03)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(drag_preview, "scale", Vector2.ONE, 0.12)


func _on_restart_pressed() -> void:
	deck.clear()
	draw_stack.clear()
	columns.clear()
	active_categories.clear()
	active_order.clear()
	selected.clear()
	steps_left = STARTING_STEPS
	next_card_id = 1
	game_over = false
	status_text = "点击牌堆开始"
	_init_level()
	_render()


func _selection_for_draw(card_index: int) -> Dictionary:
	if card_index != draw_stack.size() - 1:
		return {}
	var card: Dictionary = draw_stack[card_index]
	return {
		"source": "draw",
		"index": card_index,
		"cards": [card],
		"return_position": _draw_card_position(card_index),
		"drag_offset_y": 0.0,
	}


func _selection_for_board(col_idx: int, card_idx: int) -> Dictionary:
	if col_idx < 0 or col_idx >= columns.size():
		return {}
	var column: Array = columns[col_idx]
	if card_idx < 0 or card_idx >= column.size():
		return {}
	var card: Dictionary = column[card_idx]
	var group_start := _group_start_index(column)
	if not card["face_up"] or card_idx < group_start:
		return {}
	return {
		"source": "board",
		"col": col_idx,
		"start": group_start,
		"cards": column.slice(group_start),
		"return_position": Vector2(_column_x(col_idx), BOARD_Y + group_start * STACK_STEP),
		"drag_offset_y": float(card_idx - group_start) * STACK_STEP,
	}


func _move_selected_to_column(col_idx: int) -> bool:
	var cards: Array = selected.get("cards", [])
	if cards.is_empty():
		return false
	var target: Array = columns[col_idx]
	if selected.get("source") == "board" and selected.get("col") == col_idx:
		return false
	if not target.is_empty():
		var last: Dictionary = target[target.size() - 1]
		if not last["face_up"] or last["type"] == "category":
			return false
		if last["category"] != _group_category(cards):
			return false
	_remove_selected_from_source()
	for card in cards:
		card["face_up"] = true
		target.append(card)
		previous_card_positions[card["id"]] = Vector2(_column_x(col_idx), BOARD_Y + (target.size() - 1) * STACK_STEP)
		suppress_next_move_animations[card["id"]] = true
	status_text = "移动到 4 区"
	return true


func _move_selected_to_active_category(category: String) -> bool:
	var cards: Array = selected.get("cards", [])
	if cards.is_empty():
		return false
	if _group_has_category(cards):
		return false
	if _group_category(cards) != category:
		return false
	_remove_selected_from_source()
	_collect_words(category, cards)
	status_text = "收集到：" + category
	return true


func _move_selected_to_empty_category(slot_idx: int) -> bool:
	var cards: Array = selected.get("cards", [])
	if cards.is_empty():
		return false
	if slot_idx < 0 or slot_idx >= MAX_CATEGORY_SLOTS:
		return false
	if _category_slot_occupied(slot_idx):
		return false
	var category := ""
	for card in cards:
		if card["type"] == "category":
			category = card["category"]
	if category == "":
		return false
	if active_categories.has(category):
		return false
	for card in cards:
		if card["category"] != category:
			return false
	_remove_selected_from_source()
	active_categories[category] = {"collected": []}
	_set_category_slot(slot_idx, category)
	_collect_words(category, cards)
	status_text = "类别进入 3 区：" + category
	return true


func _remove_selected_from_source() -> void:
	if selected.get("source") == "draw":
		draw_stack.remove_at(selected["index"])
	elif selected.get("source") == "board":
		var col_idx: int = selected["col"]
		var start: int = selected["start"]
		var column: Array = columns[col_idx]
		while column.size() > start:
			column.remove_at(column.size() - 1)
		_reveal_bottom_card(col_idx)


func _reveal_bottom_card(col_idx: int) -> void:
	var column: Array = columns[col_idx]
	if column.is_empty():
		return
	var bottom: Dictionary = column[column.size() - 1]
	if not bottom["face_up"]:
		bottom["face_up"] = true


func _collect_words(category: String, cards: Array) -> void:
	var state: Dictionary = active_categories[category]
	var collected: Array = state["collected"]
	for card in cards:
		if card["type"] == "word" and card["category"] == category and not collected.has(card["name"]):
			collected.append(card["name"])
	if collected.size() >= categories[category].size():
		active_categories.erase(category)
		_clear_category_slot(category)
		status_text = category + " 已集齐并移除"


func _after_successful_move() -> void:
	if selected.has("absorb_target_position") and drag_preview != null and is_instance_valid(drag_preview):
		_animate_category_absorb()
		return
	if drag_preview != null:
		drag_preview.queue_free()
		drag_preview = null
	_suppress_selected_move_animations()
	selected.clear()
	_consume_step(status_text)


func _animate_category_absorb() -> void:
	absorbing_drag_preview = drag_preview
	drag_preview = null
	var slot_position: Vector2 = selected.get("absorb_target_position", Vector2.ZERO)
	pending_absorb_slot = int(selected.get("absorb_target_slot", -1))
	var target_center_global: Vector2 = get_global_transform() * (slot_position + Vector2(CARD_W, CARD_H) * 0.5)
	absorbing_drag_preview.pivot_offset = Vector2.ZERO
	var final_size := absorbing_drag_preview.size * CATEGORY_ABSORB_FINAL_SCALE
	var target_global := target_center_global - final_size * 0.5
	var move_time := CATEGORY_ABSORB_ANIM_TIME * 0.75
	var fade_time := CATEGORY_ABSORB_ANIM_TIME * 0.25
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(absorbing_drag_preview, "global_position", target_global, move_time)
	tween.tween_property(absorbing_drag_preview, "scale", Vector2(CATEGORY_ABSORB_FINAL_SCALE, CATEGORY_ABSORB_FINAL_SCALE), move_time)
	tween.chain().tween_property(absorbing_drag_preview, "modulate:a", 0.0, fade_time)
	tween.tween_callback(_finish_category_absorb_animation)


func _finish_category_absorb_animation() -> void:
	if is_instance_valid(absorbing_drag_preview):
		absorbing_drag_preview.queue_free()
	absorbing_drag_preview = null
	if _pulse_absorb_category_slot(pending_absorb_slot, _finish_category_absorb_pulse):
		return
	_finish_category_absorb_pulse()


func _finish_category_absorb_pulse() -> void:
	pending_absorb_slot = -1
	selected.clear()
	_consume_step(status_text)


func _pulse_absorb_category_slot(slot_idx: int, finished_callback: Callable = Callable()) -> bool:
	var category_button := _find_category_slot_button(slot_idx)
	if category_button == null:
		return false
	category_button.pivot_offset = category_button.size * 0.5
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(category_button, "scale", Vector2(1.07, 1.07), 0.08)
	tween.tween_property(category_button, "scale", Vector2.ONE, 0.12)
	if finished_callback.is_valid():
		tween.tween_callback(finished_callback)
	return true


func _find_category_slot_button(slot_idx: int) -> Control:
	for child in get_children():
		var found := _find_category_slot_button_in_node(child, slot_idx)
		if found != null:
			return found
	return null


func _find_category_slot_button_in_node(node: Node, slot_idx: int) -> Control:
	if node is Control and node.has_meta("category_slot") and int(node.get_meta("category_slot")) == slot_idx:
		return node
	for child in node.get_children():
		var found := _find_category_slot_button_in_node(child, slot_idx)
		if found != null:
			return found
	return null


func _suppress_selected_move_animations() -> void:
	for card in selected.get("cards", []):
		suppress_next_move_animations[card["id"]] = true


func _consume_step(message: String) -> void:
	steps_left -= 1
	status_text = message
	_check_end_state()
	_render()


func _check_end_state() -> void:
	if _is_win():
		game_over = true
		status_text = "过关成功"
		return
	if steps_left <= 0:
		game_over = true
		status_text = "步数用完"
		return
	if deck.is_empty() and draw_stack.is_empty() and not _has_any_legal_move():
		game_over = true
		status_text = "无牌可动"


func _is_win() -> bool:
	if not deck.is_empty() or not draw_stack.is_empty() or not active_categories.is_empty():
		return false
	for column in columns:
		if not column.is_empty():
			return false
	return true


func _has_any_legal_move() -> bool:
	if _top_draw_has_move():
		return true
	for col_idx in range(columns.size()):
		var group := _bottom_group(columns[col_idx])
		if group.is_empty():
			continue
		if _group_has_move(group, col_idx):
			return true
	return false


func _top_draw_has_move() -> bool:
	if draw_stack.is_empty():
		return false
	return _group_has_move([draw_stack[draw_stack.size() - 1]], -1)


func _group_has_move(cards: Array, source_col: int) -> bool:
	var group_category := _group_category(cards)
	if not _group_has_category(cards) and active_categories.has(group_category):
		return true
	if _group_has_category(cards) and _has_empty_category_slot() and not active_categories.has(group_category):
		return true
	for col_idx in range(columns.size()):
		if col_idx == source_col:
			continue
		var target: Array = columns[col_idx]
		if target.is_empty():
			return true
		var last: Dictionary = target[target.size() - 1]
		if last["face_up"] and last["type"] == "word" and last["category"] == group_category:
			return true
	return false


func _category_slot_occupied(slot_idx: int) -> bool:
	return slot_idx < active_order.size() and active_order[slot_idx] != "" and active_categories.has(active_order[slot_idx])


func _set_category_slot(slot_idx: int, category: String) -> void:
	while active_order.size() <= slot_idx:
		active_order.append("")
	active_order[slot_idx] = category


func _clear_category_slot(category: String) -> void:
	for i in range(active_order.size()):
		if active_order[i] == category:
			active_order[i] = ""
			return


func _has_empty_category_slot() -> bool:
	if active_order.size() < MAX_CATEGORY_SLOTS:
		return true
	for i in range(MAX_CATEGORY_SLOTS):
		if active_order[i] == "" or not active_categories.has(active_order[i]):
			return true
	return false


func _bottom_group(column: Array) -> Array:
	if column.is_empty():
		return []
	var start := _group_start_index(column)
	if start < 0:
		return []
	return column.slice(start)


func _group_start_index(column: Array) -> int:
	if column.is_empty():
		return -1
	var last: Dictionary = column[column.size() - 1]
	if not last["face_up"]:
		return column.size()
	var category: String = last["category"]
	var start := column.size() - 1
	for i in range(column.size() - 2, -1, -1):
		var card: Dictionary = column[i]
		if not card["face_up"] or card["category"] != category:
			break
		if last["type"] == "word" and card["type"] == "category":
			break
		start = i
	return start


func _group_category(cards: Array) -> String:
	if cards.is_empty():
		return ""
	return cards[0]["category"]


func _group_has_category(cards: Array) -> bool:
	for card in cards:
		if card["type"] == "category":
			return true
	return false


func _group_label(cards: Array) -> String:
	var names: Array[String] = []
	for card in cards:
		names.append(card["name"])
	return " / ".join(names)


func _selected_has_card(card_id: int) -> bool:
	if selected.is_empty():
		return false
	for card in selected.get("cards", []):
		if card["id"] == card_id:
			return true
	return false
