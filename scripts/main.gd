extends Control

const CARD_W := 78.0
const CARD_H := 104.0
const STACK_STEP := 24.0
const BOARD_DROP_EXTRA_BOTTOM := 96.0
const COL_GAP := 14.0
const DRAW_Y := 24.0
const CATEGORY_Y := 158.0
const BOARD_Y := 282.0
const MAX_CATEGORY_SLOTS := 4
const STARTING_STEPS := 120
const BOARD_COLUMN_COUNT := 4
const BOARD_CARDS_PER_COLUMN := 6
const CATEGORIES_PER_GAME := 9
const MAX_EIGHT_WORD_CATEGORIES := 1
const MAX_SEVEN_WORD_CATEGORIES := 2
const SOLVER_MAX_DEAL_ATTEMPTS := 80
const SOLVER_MAX_STATES_PER_DEAL := 30000
const SOLVER_MAX_SOLUTION_STEPS := 220
const SOLVER_DFS_SAMPLE_MIN := 5
const SOLVER_DFS_SAMPLE_MAX := 10
const SOLVER_DFS_PRIORITY_JITTER := 4.0
const SOLVER_STEP_PADDING_RATIO := 0.25
const SOLVER_STEP_PADDING_MIN := 16
const DRAG_THRESHOLD := 8.0
const ANIM_TIME := 0.18
const DRAW_ANIM_TIME := 0.28
const DRAW_RETARGET_TIME := 0.14
const CARD_FLIP_FACE_TIME := 0.38
const WASH_FLIP_FACE_TIME := 0.24
const DRAG_CANCEL_ANIM_TIME := 0.16
const CATEGORY_ABSORB_ANIM_TIME := 0.20
const CATEGORY_ABSORB_FINAL_SCALE := 0.36
const ROUND_TRANSITION_CLOSE_TIME := 0.48
const ROUND_TRANSITION_HOLD_TIME := 0.18
const ROUND_TRANSITION_OPEN_TIME := 0.58
const ROUND_TRANSITION_SEAM_H := 4.0
const MUSIC_PATH := "res://assets/audio/background_music.mp3"
const CARD_FLIP_SFX_PATH := "res://assets/audio/card_flip.wav"
const BUTTON_CLICK_SFX_PATH := "res://assets/audio/button_click.mp3"
const SFX_PLAYER_COUNT := 4
const BUTTON_SFX_PLAYER_COUNT := 3
const MUSIC_BASE_VOLUME_DB := -8.0
const SFX_BASE_VOLUME_DB := -1.2
const MUSIC_TRIM_DB := 0.0
const CARD_FLIP_SFX_TRIM_DB := -1.4
const BUTTON_CLICK_SFX_TRIM_DB := -0.6
const MUSIC_VOLUME_DB := MUSIC_BASE_VOLUME_DB + MUSIC_TRIM_DB
const CARD_FLIP_SFX_VOLUME_DB := SFX_BASE_VOLUME_DB + CARD_FLIP_SFX_TRIM_DB
const BUTTON_CLICK_SFX_VOLUME_DB := SFX_BASE_VOLUME_DB + BUTTON_CLICK_SFX_TRIM_DB

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
var menu_active := true
var steps_left := STARTING_STEPS
var next_card_id := 1
var game_over := false
var status_text := "点击牌堆开始"
var previous_card_positions := {}
var pending_spawn_positions := {}
var pending_draw_animations := {}
var animating_draw_cards := {}
var revealing_board_cards := {}
var suppress_next_move_animations := {}
var deck_animation_busy := false
var draw_animation_nodes := {}
var draw_animation_cards := {}
var draw_flights := {}
var last_deck_gui_press_frame := -1
var wash_animation_nodes: Array[Control] = []
var wash_animation_starts: Array[Vector2] = []
var wash_flight := {}
var drag_candidate := {}
var drag_preview: Control
var drag_offset := Vector2.ZERO
var returning_drag_preview: Control
var absorbing_drag_preview: Control
var pending_absorb_slot := -1
var completing_category_slot := -1
var completing_category_name := ""
var round_transition_active := false
var round_transition_overlay: Control
var round_transition_tween: Tween
var pending_round_message := ""
var music_player: AudioStreamPlayer
var card_flip_sfx_stream: AudioStream
var button_click_sfx_stream: AudioStream
var sfx_players: Array = []
var button_sfx_players: Array = []
var next_sfx_player := 0
var next_button_sfx_player := 0
var audio_initialized := false
var last_solver_attempts := 0
var last_solver_steps := 0
var last_solver_states := 0
var last_solver_found := false

var bg_color := Color("#a9d78e")
var curtain_color := Color("#94c87c")
var card_color := Color("#fbfbf4")
var category_color := Color("#ffe08a")
var card_border := Color("#161616")
var back_color := Color("#4d9be8")
var slot_color := Color(1.0, 1.0, 1.0, 0.20)
var category_empty_slot_color := Color("#f6d86a", 0.42)


func _ready() -> void:
	_init_audio()
	randomize()
	_init_level()
	_render()


func _input(event: InputEvent) -> void:
	if round_transition_active:
		return
	if menu_active:
		return
	if drag_candidate.is_empty():
		return
	if event is InputEventMouseMotion:
		_update_drag(event.position, event.global_position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_finish_drag(event.global_position)


func _process(delta: float) -> void:
	_update_draw_flights(delta)
	_update_wash_flight(delta)


func _init_audio() -> void:
	if audio_initialized:
		return
	audio_initialized = true

	var music_stream: AudioStream = load(MUSIC_PATH)
	if music_stream != null:
		_set_audio_stream_loop(music_stream, true)
		music_player = AudioStreamPlayer.new()
		music_player.set_meta("audio_player", true)
		music_player.name = "MusicPlayer"
		music_player.stream = music_stream
		music_player.volume_db = MUSIC_VOLUME_DB
		add_child(music_player)
		if music_player.is_inside_tree():
			music_player.play()
		else:
			call_deferred("_play_background_music")

	card_flip_sfx_stream = load(CARD_FLIP_SFX_PATH)
	for i in range(SFX_PLAYER_COUNT):
		var player := AudioStreamPlayer.new()
		player.set_meta("audio_player", true)
		player.name = "CardFlipSfx" + str(i + 1)
		player.stream = card_flip_sfx_stream
		player.volume_db = CARD_FLIP_SFX_VOLUME_DB
		add_child(player)
		sfx_players.append(player)

	button_click_sfx_stream = load(BUTTON_CLICK_SFX_PATH)
	for i in range(BUTTON_SFX_PLAYER_COUNT):
		var player := AudioStreamPlayer.new()
		player.set_meta("audio_player", true)
		player.name = "ButtonClickSfx" + str(i + 1)
		player.stream = button_click_sfx_stream
		player.volume_db = BUTTON_CLICK_SFX_VOLUME_DB
		add_child(player)
		button_sfx_players.append(player)


func _set_audio_stream_loop(stream: AudioStream, enabled: bool) -> void:
	for property in stream.get_property_list():
		if property.get("name", "") == "loop":
			stream.set("loop", enabled)
			return


func _play_background_music() -> void:
	if is_instance_valid(music_player) and music_player.is_inside_tree() and not music_player.playing:
		music_player.play()


func _play_card_flip_sfx() -> void:
	if card_flip_sfx_stream == null or sfx_players.is_empty():
		return
	var player: AudioStreamPlayer = sfx_players[next_sfx_player % sfx_players.size()]
	next_sfx_player += 1
	if not is_instance_valid(player) or not player.is_inside_tree():
		return
	player.stop()
	player.pitch_scale = randf_range(0.97, 1.03)
	player.play()


func _play_button_click_sfx() -> void:
	if button_click_sfx_stream == null or button_sfx_players.is_empty():
		return
	var player: AudioStreamPlayer = button_sfx_players[next_button_sfx_player % button_sfx_players.size()]
	next_button_sfx_player += 1
	if not is_instance_valid(player) or not player.is_inside_tree():
		return
	player.stop()
	player.pitch_scale = randf_range(0.98, 1.02)
	player.play()


func _audio_balanced_volume_db(group_volume_db: float, asset_trim_db: float) -> float:
	return group_volume_db + asset_trim_db


func _init_level() -> void:
	last_solver_attempts = 0
	last_solver_steps = 0
	last_solver_states = 0
	last_solver_found = false
	for attempt in range(SOLVER_MAX_DEAL_ATTEMPTS):
		_prepare_random_deal()
		var solve_result := _solve_current_deal()
		last_solver_attempts = attempt + 1
		last_solver_states += int(solve_result.get("states", 0))
		if bool(solve_result.get("solved", false)):
			last_solver_found = true
			last_solver_steps = int(solve_result.get("steps", STARTING_STEPS))
			steps_left = _steps_for_solution(last_solver_steps)
			return
	steps_left = STARTING_STEPS


func _prepare_random_deal() -> void:
	deck.clear()
	draw_stack.clear()
	active_categories.clear()
	active_order.clear()
	selected.clear()
	categories = _select_categories_for_game()
	word_to_category.clear()
	for category in categories.keys():
		for word in categories[category]:
			word_to_category[word] = category

	var all_cards := _build_full_deck()
	all_cards.shuffle()
	_deal_board_and_deck(all_cards)


func _steps_for_solution(solution_steps: int) -> int:
	var padding: int = max(SOLVER_STEP_PADDING_MIN, int(ceil(float(solution_steps) * SOLVER_STEP_PADDING_RATIO)))
	return solution_steps + padding


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
	var used_conflict_tokens := {}
	var used_lengths := {}
	for category in names:
		if selected_categories.size() >= CATEGORIES_PER_GAME:
			break
		if used_lengths.has(category_pool[category].size()) and used_lengths.size() < 5:
			continue
		if not _category_length_is_available(category, selected_categories):
			continue
		if not _category_words_are_available(category, used_words):
			continue
		if not _category_conflict_tokens_are_available(category, used_conflict_tokens):
			continue
		selected_categories[category] = category_pool[category].duplicate()
		used_lengths[category_pool[category].size()] = true
		_mark_category_words_used(category, used_words, used_conflict_tokens)
	for category in names:
		if selected_categories.size() >= CATEGORIES_PER_GAME:
			break
		if selected_categories.has(category):
			continue
		if not _category_length_is_available(category, selected_categories):
			continue
		if not _category_words_are_available(category, used_words):
			continue
		if not _category_conflict_tokens_are_available(category, used_conflict_tokens):
			continue
		selected_categories[category] = category_pool[category].duplicate()
		_mark_category_words_used(category, used_words, used_conflict_tokens)
	return selected_categories


func _category_length_is_available(category: String, selected_categories: Dictionary) -> bool:
	var length: int = category_pool[category].size()
	if length == 8:
		return _selected_category_length_count(selected_categories, 8) < MAX_EIGHT_WORD_CATEGORIES
	if length == 7:
		return _selected_category_length_count(selected_categories, 7) < MAX_SEVEN_WORD_CATEGORIES
	return true


func _selected_category_length_count(selected_categories: Dictionary, length: int) -> int:
	var count := 0
	for category in selected_categories.keys():
		if selected_categories[category].size() == length:
			count += 1
	return count


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


func _category_conflict_tokens_are_available(category: String, used_conflict_tokens: Dictionary) -> bool:
	for word in category_pool[category]:
		for token in _word_conflict_tokens(word):
			if used_conflict_tokens.has(token):
				return false
	return true


func _mark_category_words_used(category: String, used_words: Dictionary, used_conflict_tokens: Dictionary) -> void:
	for word in category_pool[category]:
		used_words[word] = true
		for token in _word_conflict_tokens(word):
			used_conflict_tokens[token] = true


func _word_conflict_tokens(word: String) -> Array[String]:
	var tokens: Array[String] = []
	var clean_word := word.strip_edges()
	var length := clean_word.length()
	if length <= 0:
		return tokens
	if length == 1:
		tokens.append(clean_word)
		return tokens
	var first := clean_word.substr(0, 1)
	var last := clean_word.substr(length - 1, 1)
	if not _is_weak_conflict_token(first):
		tokens.append(first)
	if first != last and not _is_weak_conflict_token(last):
		tokens.append(last)
	return tokens


func _is_weak_conflict_token(token: String) -> bool:
	return token in ["子", "色", "人", "师", "家", "具", "品", "类", "术", "车", "机"]


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

	_ensure_bottom_visible_opening_mix()

	for column in columns:
		if not column.is_empty():
			column[column.size() - 1]["face_up"] = true


func _ensure_bottom_visible_opening_mix() -> void:
	_ensure_bottom_visible_category()
	_ensure_bottom_visible_words(2)


func _ensure_bottom_visible_category() -> void:
	if _bottom_visible_has_category():
		return
	var bottom_columns := _non_empty_column_indices()
	var hidden_categories := _hidden_category_locations()
	if bottom_columns.is_empty() or hidden_categories.is_empty():
		return

	var target_col: int = bottom_columns[randi_range(0, bottom_columns.size() - 1)]
	var target_idx: int = columns[target_col].size() - 1
	var target_card: Dictionary = columns[target_col][target_idx]
	var source: Dictionary = hidden_categories[randi_range(0, hidden_categories.size() - 1)]

	if source["area"] == "deck":
		var deck_idx: int = source["index"]
		columns[target_col][target_idx] = deck[deck_idx]
		deck[deck_idx] = target_card
	else:
		var source_col: int = source["col"]
		var source_idx: int = source["index"]
		columns[target_col][target_idx] = columns[source_col][source_idx]
		columns[source_col][source_idx] = target_card


func _ensure_bottom_visible_words(min_word_count: int) -> void:
	while _bottom_visible_count("word") < min_word_count:
		var bottom_categories := _bottom_visible_locations("category")
		var hidden_words := _hidden_card_locations("word")
		if bottom_categories.is_empty() or hidden_words.is_empty():
			return
		var target: Dictionary = bottom_categories[randi_range(0, bottom_categories.size() - 1)]
		var source: Dictionary = hidden_words[randi_range(0, hidden_words.size() - 1)]
		_swap_location_cards(target, source)


func _bottom_visible_has_category() -> bool:
	return _bottom_visible_count("category") > 0


func _bottom_visible_count(card_type: String) -> int:
	var count := 0
	for column in columns:
		if not column.is_empty():
			var bottom: Dictionary = column[column.size() - 1]
			if bottom["type"] == card_type:
				count += 1
	return count


func _bottom_visible_locations(card_type: String) -> Array[Dictionary]:
	var locations: Array[Dictionary] = []
	for col_idx in range(columns.size()):
		var column: Array = columns[col_idx]
		if column.is_empty():
			continue
		var card_idx: int = column.size() - 1
		var card: Dictionary = column[card_idx]
		if card["type"] == card_type:
			locations.append({"area": "board", "col": col_idx, "index": card_idx})
	return locations


func _non_empty_column_indices() -> Array[int]:
	var indices: Array[int] = []
	for col_idx in range(columns.size()):
		if not columns[col_idx].is_empty():
			indices.append(col_idx)
	return indices


func _hidden_category_locations() -> Array[Dictionary]:
	return _hidden_card_locations("category")


func _hidden_card_locations(card_type: String) -> Array[Dictionary]:
	var locations: Array[Dictionary] = []
	for col_idx in range(columns.size()):
		var column: Array = columns[col_idx]
		for card_idx in range(max(0, column.size() - 1)):
			var card: Dictionary = column[card_idx]
			if card["type"] == card_type:
				locations.append({"area": "board", "col": col_idx, "index": card_idx})
	for deck_idx in range(deck.size()):
		var card: Dictionary = deck[deck_idx]
		if card["type"] == card_type:
			locations.append({"area": "deck", "index": deck_idx})
	return locations


func _swap_location_cards(first: Dictionary, second: Dictionary) -> void:
	var first_card: Dictionary = _card_at_location(first)
	var second_card: Dictionary = _card_at_location(second)
	_set_card_at_location(first, second_card)
	_set_card_at_location(second, first_card)


func _card_at_location(location: Dictionary) -> Dictionary:
	if location["area"] == "deck":
		return deck[int(location["index"])]
	return columns[int(location["col"])][int(location["index"])]


func _set_card_at_location(location: Dictionary, card: Dictionary) -> void:
	if location["area"] == "deck":
		deck[int(location["index"])] = card
	else:
		columns[int(location["col"])][int(location["index"])] = card


func _solve_current_deal(max_solution_steps := SOLVER_MAX_SOLUTION_STEPS) -> Dictionary:
	var sample_count := randi_range(SOLVER_DFS_SAMPLE_MIN, SOLVER_DFS_SAMPLE_MAX)
	var solved_steps: Array[int] = []
	var total_states := 0
	for sample_idx in range(sample_count):
		var state_budget: int = max(1200, int(SOLVER_MAX_STATES_PER_DEAL / sample_count))
		var result := _solve_current_deal_dfs(max_solution_steps, state_budget)
		total_states += int(result.get("states", 0))
		if bool(result.get("solved", false)):
			solved_steps.append(int(result.get("steps", 0)))
	if solved_steps.is_empty():
		return {"solved": false, "steps": 0, "states": total_states, "samples": sample_count}
	var total_steps := 0
	for step_count in solved_steps:
		total_steps += step_count
	var average_steps := int(round(float(total_steps) / float(solved_steps.size())))
	return {
		"solved": true,
		"steps": average_steps,
		"states": total_states,
		"samples": sample_count,
		"solved_samples": solved_steps.size(),
	}


func _solve_current_deal_dfs(max_solution_steps := SOLVER_MAX_SOLUTION_STEPS, state_budget := SOLVER_MAX_STATES_PER_DEAL) -> Dictionary:
	var card_info := _solver_card_info()
	var initial_state := _solver_initial_state()
	var stack: Array[Dictionary] = [{"state": initial_state, "steps": 0}]
	var best_seen := {}
	var states_checked := 0

	while not stack.is_empty() and states_checked < state_budget:
		var entry: Dictionary = stack.pop_back()
		var state: Dictionary = entry["state"]
		var steps: int = int(entry["steps"])
		var key := _solver_state_key(state)
		if best_seen.has(key) and int(best_seen[key]) <= steps:
			continue
		best_seen[key] = steps
		states_checked += 1

		if _solver_is_win(state):
			return {"solved": true, "steps": steps, "states": states_checked}
		if steps >= max_solution_steps:
			continue

		var next_entries := _solver_next_entries(state, card_info, steps)
		_solver_randomize_entry_order(next_entries)
		for next_entry in next_entries:
			stack.append(next_entry)

	return {"solved": false, "steps": 0, "states": states_checked}


func _solver_randomize_entry_order(entries: Array[Dictionary]) -> void:
	for entry in entries:
		entry["rank"] = float(entry["priority"]) + randf_range(-SOLVER_DFS_PRIORITY_JITTER, SOLVER_DFS_PRIORITY_JITTER)
	entries.shuffle()
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["rank"]) < float(b["rank"])
	)


func _solver_card_info() -> Dictionary:
	var info := {}
	for card in deck:
		_solver_add_card_info(info, card)
	for column in columns:
		for card in column:
			_solver_add_card_info(info, card)
	return info


func _solver_add_card_info(info: Dictionary, card: Dictionary) -> void:
	info[int(card["id"])] = {
		"type": card["type"],
		"name": card["name"],
		"category": card["category"],
	}


func _solver_initial_state() -> Dictionary:
	var state := {
		"deck": [],
		"draw": [],
		"cols": [],
		"active": {},
	}
	for card in deck:
		state["deck"].append(int(card["id"]))
	for column in columns:
		var solver_col: Array[int] = []
		for card in column:
			var card_id := int(card["id"])
			solver_col.append(card_id if bool(card["face_up"]) else -card_id)
		state["cols"].append(solver_col)
	return state


func _solver_next_entries(state: Dictionary, card_info: Dictionary, steps: int) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	_solver_add_source_moves(entries, state, card_info, steps)
	var deck_cards: Array = state["deck"]
	if not deck_cards.is_empty():
		var next_state := _solver_clone_state(state)
		var next_deck: Array = next_state["deck"]
		var next_draw: Array = next_state["draw"]
		next_draw.append(int(next_deck.pop_back()))
		entries.append({"state": next_state, "steps": steps + 1, "priority": 1})
	return entries


func _solver_add_source_moves(entries: Array[Dictionary], state: Dictionary, card_info: Dictionary, steps: int) -> void:
	var sources: Array[Dictionary] = []
	var draw_cards: Array = state["draw"]
	if not draw_cards.is_empty():
		sources.append({
			"source": "draw",
			"source_col": -1,
			"start": -1,
			"group": [int(draw_cards[draw_cards.size() - 1])],
		})

	var cols: Array = state["cols"]
	for col_idx in range(cols.size()):
		var col: Array = cols[col_idx]
		var start := _solver_group_start_index(col, card_info)
		if start < 0:
			continue
		var group: Array[int] = []
		for i in range(start, col.size()):
			group.append(abs(int(col[i])))
		sources.append({
			"source": "board",
			"source_col": col_idx,
			"start": start,
			"group": group,
		})

	for source in sources:
		var has_progress_move := _solver_has_category_progress_move(state, card_info, source)
		_solver_add_category_moves(entries, state, card_info, source, steps)
		if not has_progress_move:
			_solver_add_column_moves(entries, state, card_info, source, steps)


func _solver_has_category_progress_move(state: Dictionary, card_info: Dictionary, source: Dictionary) -> bool:
	var group: Array = source["group"]
	if group.is_empty():
		return false
	var category := _solver_group_category(group, card_info)
	var active: Dictionary = state["active"]
	var has_category := _solver_group_has_category(group, card_info)
	if not has_category and active.has(category):
		return true
	return has_category \
		and not active.has(category) \
		and active.size() < MAX_CATEGORY_SLOTS \
		and _solver_group_is_single_category(group, category, card_info)


func _solver_add_category_moves(entries: Array[Dictionary], state: Dictionary, card_info: Dictionary, source: Dictionary, steps: int) -> void:
	var group: Array = source["group"]
	if group.is_empty():
		return
	var category := _solver_group_category(group, card_info)
	var active: Dictionary = state["active"]
	var has_category := _solver_group_has_category(group, card_info)

	if not has_category and active.has(category):
		var next_state := _solver_clone_state(state)
		_solver_remove_source(next_state, source)
		var completed := _solver_collect_words(next_state, group, card_info)
		entries.append({"state": next_state, "steps": steps + 1, "priority": 22 if completed else 14})
		return

	if has_category and not active.has(category) and active.size() < MAX_CATEGORY_SLOTS and _solver_group_is_single_category(group, category, card_info):
		var next_state := _solver_clone_state(state)
		_solver_remove_source(next_state, source)
		next_state["active"][category] = {}
		var completed := _solver_collect_words(next_state, group, card_info)
		entries.append({"state": next_state, "steps": steps + 1, "priority": 20 if completed else 12})


func _solver_add_column_moves(entries: Array[Dictionary], state: Dictionary, card_info: Dictionary, source: Dictionary, steps: int) -> void:
	var group: Array = source["group"]
	if group.is_empty():
		return
	var category := _solver_group_category(group, card_info)
	var cols: Array = state["cols"]
	var empty_target_used := false
	for target_col in range(cols.size()):
		if int(source["source_col"]) == target_col:
			continue
		var target: Array = cols[target_col]
		var target_is_empty := target.is_empty()
		if target_is_empty:
			if empty_target_used:
				continue
			empty_target_used = true
		elif not _solver_can_stack_on_column(target, category, card_info):
			continue

		var next_state := _solver_clone_state(state)
		var reveals_card := _solver_source_reveals_card(next_state, source)
		_solver_remove_source(next_state, source)
		var next_cols: Array = next_state["cols"]
		var next_target: Array = next_cols[target_col]
		for card_id in group:
			next_target.append(abs(int(card_id)))
		var priority := 8 if reveals_card else 4
		if not target_is_empty:
			priority += 2
		entries.append({"state": next_state, "steps": steps + 1, "priority": priority})


func _solver_group_start_index(col: Array, card_info: Dictionary) -> int:
	if col.is_empty():
		return -1
	var last_value := int(col[col.size() - 1])
	if last_value < 0:
		return -1
	var last_info: Dictionary = card_info[abs(last_value)]
	var category: String = last_info["category"]
	var start := col.size() - 1
	for i in range(col.size() - 2, -1, -1):
		var value := int(col[i])
		if value < 0:
			break
		var info: Dictionary = card_info[abs(value)]
		if info["category"] != category:
			break
		if last_info["type"] == "word" and info["type"] == "category":
			break
		start = i
	return start


func _solver_can_stack_on_column(target: Array, category: String, card_info: Dictionary) -> bool:
	if target.is_empty():
		return true
	var last_value := int(target[target.size() - 1])
	if last_value < 0:
		return false
	var info: Dictionary = card_info[abs(last_value)]
	return info["type"] == "word" and info["category"] == category


func _solver_source_reveals_card(state: Dictionary, source: Dictionary) -> bool:
	if source["source"] != "board":
		return false
	var cols: Array = state["cols"]
	var col: Array = cols[int(source["source_col"])]
	var start := int(source["start"])
	return start > 0 and int(col[start - 1]) < 0


func _solver_remove_source(state: Dictionary, source: Dictionary) -> void:
	if source["source"] == "draw":
		var draw_cards: Array = state["draw"]
		draw_cards.pop_back()
		return

	var cols: Array = state["cols"]
	var col: Array = cols[int(source["source_col"])]
	var start := int(source["start"])
	while col.size() > start:
		col.remove_at(col.size() - 1)
	if not col.is_empty() and int(col[col.size() - 1]) < 0:
		col[col.size() - 1] = abs(int(col[col.size() - 1]))


func _solver_collect_words(state: Dictionary, group: Array, card_info: Dictionary) -> bool:
	if group.is_empty():
		return false
	var category := _solver_group_category(group, card_info)
	var active: Dictionary = state["active"]
	if not active.has(category):
		return false
	var collected: Dictionary = active[category]
	for card_id in group:
		var info: Dictionary = card_info[abs(int(card_id))]
		if info["type"] == "word" and info["category"] == category:
			collected[info["name"]] = true
	if collected.size() >= categories[category].size():
		active.erase(category)
		return true
	return false


func _solver_group_category(group: Array, card_info: Dictionary) -> String:
	if group.is_empty():
		return ""
	var info: Dictionary = card_info[abs(int(group[0]))]
	return info["category"]


func _solver_group_has_category(group: Array, card_info: Dictionary) -> bool:
	for card_id in group:
		var info: Dictionary = card_info[abs(int(card_id))]
		if info["type"] == "category":
			return true
	return false


func _solver_group_is_single_category(group: Array, category: String, card_info: Dictionary) -> bool:
	for card_id in group:
		var info: Dictionary = card_info[abs(int(card_id))]
		if info["category"] != category:
			return false
	return true


func _solver_clone_state(state: Dictionary) -> Dictionary:
	var clone := {
		"deck": state["deck"].duplicate(),
		"draw": state["draw"].duplicate(),
		"cols": [],
		"active": {},
	}
	for col in state["cols"]:
		clone["cols"].append(col.duplicate())
	for category in state["active"].keys():
		clone["active"][category] = state["active"][category].duplicate()
	return clone


func _solver_is_win(state: Dictionary) -> bool:
	if not state["deck"].is_empty() or not state["draw"].is_empty() or not state["active"].is_empty():
		return false
	for col in state["cols"]:
		if not col.is_empty():
			return false
	return true


func _solver_state_key(state: Dictionary) -> String:
	var parts: Array[String] = []
	parts.append(_solver_join_ints(state["deck"]))
	parts.append(_solver_join_ints(state["draw"]))
	var column_parts: Array[String] = []
	for col in state["cols"]:
		column_parts.append(_solver_join_ints(col))
	column_parts.sort()
	parts.append(_solver_join_strings(column_parts))
	var active_keys: Array = state["active"].keys()
	active_keys.sort()
	var active_parts: Array[String] = []
	for category in active_keys:
		var collected: Dictionary = state["active"][category]
		var words: Array = collected.keys()
		words.sort()
		active_parts.append(str(category) + ":" + _solver_join_strings(words))
	parts.append(_solver_join_strings(active_parts))
	return "|".join(PackedStringArray(parts))


func _solver_join_ints(values: Array) -> String:
	var strings: Array[String] = []
	for value in values:
		strings.append(str(int(value)))
	return ",".join(PackedStringArray(strings))


func _solver_join_strings(values: Array) -> String:
	var strings: Array[String] = []
	for value in values:
		strings.append(str(value))
	return ",".join(PackedStringArray(strings))


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
		if _should_preserve_render_child(child):
			continue
		child.queue_free()
	drag_preview = null

	var next_card_positions := {}

	var bg := ColorRect.new()
	bg.color = bg_color
	bg.position = Vector2.ZERO
	bg.size = get_viewport_rect().size
	add_child(bg)

	if menu_active:
		_render_start_menu()
		previous_card_positions = next_card_positions
		return

	_render_top_controls()
	_render_draw_area(next_card_positions)
	_render_deck_area()
	_render_category_area()
	_render_board_area(next_card_positions)

	if game_over:
		_render_overlay()

	previous_card_positions = next_card_positions


func _should_preserve_render_child(child: Node) -> bool:
	if child.has_meta("audio_player"):
		return true
	if child.has_meta("round_transition_overlay"):
		return not child.is_queued_for_deletion()
	for node in draw_animation_nodes.values():
		if child == node:
			return true
	for node in wash_animation_nodes:
		if child == node:
			return true
	return false


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
		btn.set_meta("draw_card_button", true)
		btn.position = pos
		btn.size = Vector2(CARD_W, CARD_H)
		btn.gui_input.connect(_on_draw_card_gui_input.bind(card_index))
		add_child(btn)
		_animate_card_node(btn, card, pos)
		next_card_positions[card["id"]] = pos


func _render_deck_area() -> void:
	var btn := Control.new()
	btn.set_meta("deck_button", true)
	btn.position = Vector2(_column_x(3), DRAW_Y)
	btn.size = Vector2(78, 104)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var has_deck_cards := deck.size() > 0
	var deck_style := _style(back_color, Color.WHITE, 4, 14) if has_deck_cards else _style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 14)
	btn.gui_input.connect(_on_deck_gui_input)
	var surface := Panel.new()
	surface.set_meta("deck_surface", true)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.position = Vector2.ZERO
	surface.size = btn.size
	surface.add_theme_stylebox_override("panel", deck_style)
	btn.add_child(surface)
	if not has_deck_cards:
		_add_dashed_outline(btn, btn.size, Color(1, 1, 1, 0.62), 3.0, 10.0, 7.0)
		_add_generated_label(btn, _deck_button_text(), Vector2(4, 40), Vector2(70, 24), 16, Color(1, 1, 1, 0.72))
	else:
		_add_deck_count_labels(btn)
	add_child(btn)


func _render_top_controls() -> void:
	var restart := _make_top_button("重开", Vector2(12, 8), "restart_button")
	restart.pressed.connect(_on_restart_pressed)
	add_child(restart)

	var home := _make_top_button("首页", Vector2(70, 8), "home_button")
	home.pressed.connect(_on_home_pressed)
	add_child(home)

	_add_label("剩余步数：" + str(steps_left), Vector2(12, 42), Vector2(116, 20), 13, Color(1, 1, 1, 0.82), false)


func _make_top_button(text: String, pos: Vector2, meta_name: String) -> Button:
	var btn := Button.new()
	btn.set_meta(meta_name, true)
	btn.position = pos
	btn.size = Vector2(50, 28)
	btn.text = text
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color("#443b32"))
	btn.add_theme_color_override("font_hover_color", Color("#443b32"))
	btn.add_theme_color_override("font_pressed_color", Color("#443b32"))
	btn.add_theme_color_override("font_focus_color", Color("#443b32"))
	var style := _style(Color("#ffe08a"), card_border, 3, 8)
	_apply_button_style_states(btn, style)
	_attach_button_press_feedback(btn)
	return btn


func _render_category_area() -> void:
	for i in range(MAX_CATEGORY_SLOTS):
		var pos := Vector2(_column_x(i), CATEGORY_Y)
		if i < active_order.size() and active_order[i] != "" and active_categories.has(active_order[i]):
			var category: String = active_order[i]
			var state: Dictionary = active_categories[category]
			var total: int = categories[category].size()
			var count: int = state["collected"].size()
			var btn := Button.new()
			btn.set_meta("category_slot", i)
			btn.position = pos
			btn.size = Vector2(CARD_W, CARD_H)
			btn.text = ""
			btn.disabled = false
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_theme_color_override("font_color", Color("#443b32"))
			btn.add_theme_color_override("font_hover_color", Color("#443b32"))
			btn.add_theme_color_override("font_pressed_color", Color("#443b32"))
			btn.add_theme_color_override("font_focus_color", Color("#443b32"))
			var category_style := _style(category_color, card_border, 4, 10)
			_apply_button_style_states(btn, category_style)
			_add_category_card_labels(btn, category, str(count) + "/" + str(total), Color("#443b32"))
			add_child(btn)
		else:
			var slot := Button.new()
			slot.set_meta("category_empty_slot", i)
			slot.position = pos
			slot.size = Vector2(CARD_W, CARD_H)
			slot.text = ""
			slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var slot_style := _style(category_empty_slot_color, Color(0, 0, 0, 0), 0, 10)
			_apply_button_style_states(slot, slot_style)
			_add_dashed_outline(slot, slot.size, Color("#ffe070", 0.86), 2.0, 8.0, 6.0, "category_slot_dash")
			add_child(slot)


func _render_board_area(next_card_positions: Dictionary) -> void:
	for col_idx in range(columns.size()):
		var x := _column_x(col_idx)
		var column: Array = columns[col_idx]
		if column.is_empty():
			var empty := Button.new()
			empty.set_meta("board_empty_slot", true)
			empty.position = Vector2(x, BOARD_Y)
			empty.size = Vector2(CARD_W, CARD_H)
			empty.text = "+"
			empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
			empty.add_theme_font_size_override("font_size", 30)
			empty.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
			empty.add_theme_color_override("font_hover_color", Color(1, 1, 1, 0.45))
			empty.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 0.45))
			empty.add_theme_color_override("font_focus_color", Color(1, 1, 1, 0.45))
			var empty_style := _style(slot_color, Color(1, 1, 1, 0.35), 2, 10)
			_apply_button_style_states(empty, empty_style)
			add_child(empty)
			continue

		for card_idx in range(column.size()):
			var card: Dictionary = column[card_idx]
			var pos := Vector2(x, BOARD_Y + card_idx * STACK_STEP)
			var is_selected: bool = _selected_has_card(card["id"])
			var selectable: bool = bool(card["face_up"]) and card_idx >= _group_start_index(column)
			var is_revealing: bool = revealing_board_cards.has(card["id"])
			var covered_by_next := card_idx < column.size() - 1
			var board_text := "" if covered_by_next and card["face_up"] else _card_text_for_board(column, card_idx)
			var visual_card := card
			var visual_text := board_text
			if is_revealing:
				visual_card = card.duplicate()
				visual_card["face_up"] = false
				visual_text = ""
			var btn := _make_card_button(visual_card, is_selected, selectable and not is_revealing, visual_text)
			btn.set_meta("board_card_button", true)
			btn.position = pos
			btn.size = Vector2(CARD_W, CARD_H)
			btn.gui_input.connect(_on_board_card_gui_input.bind(col_idx, card_idx))
			add_child(btn)
			if is_revealing:
				_start_board_reveal_animation(btn, card, selectable, board_text)
			else:
				_animate_card_node(btn, card, pos)
			next_card_positions[card["id"]] = pos
			if covered_by_next and card["face_up"] and not is_revealing:
				_add_card_strip_label(btn, _card_text_for_board(column, card_idx))


func _refresh_draw_area_only() -> void:
	if not is_inside_tree():
		return
	for child in get_children():
		if child is Control and child.has_meta("draw_card_button"):
			child.free()
	var next_card_positions := {}
	_render_draw_area(next_card_positions)
	for card_id in next_card_positions.keys():
		previous_card_positions[card_id] = next_card_positions[card_id]


func _refresh_board_area_only() -> void:
	if not is_inside_tree():
		return
	for child in get_children():
		if child is Control and (child.has_meta("board_card_button") or child.has_meta("board_empty_slot")):
			child.free()
	var next_card_positions := {}
	_render_board_area(next_card_positions)
	for card_id in next_card_positions.keys():
		previous_card_positions[card_id] = next_card_positions[card_id]


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
	restart.text = "再来一局"
	restart.add_theme_font_size_override("font_size", 20)
	restart.add_theme_color_override("font_color", Color("#544b4b"))
	restart.add_theme_color_override("font_hover_color", Color("#544b4b"))
	restart.add_theme_color_override("font_pressed_color", Color("#544b4b"))
	restart.add_theme_color_override("font_focus_color", Color("#544b4b"))
	var restart_style := _style(Color("#ffe08a"), card_border, 3, 10)
	_apply_button_style_states(restart, restart_style)
	restart.pressed.connect(_on_restart_pressed)
	_attach_button_press_feedback(restart)
	add_child(restart)


func _render_start_menu() -> void:
	var start := Button.new()
	start.set_meta("start_button", true)
	start.position = Vector2((get_viewport_rect().size.x - 180.0) * 0.5, 332)
	start.size = Vector2(180, 48)
	start.text = "开始游戏"
	start.add_theme_font_size_override("font_size", 22)
	start.add_theme_color_override("font_color", Color("#443b32"))
	start.add_theme_color_override("font_hover_color", Color("#443b32"))
	start.add_theme_color_override("font_pressed_color", Color("#443b32"))
	start.add_theme_color_override("font_focus_color", Color("#443b32"))
	var start_style := _style(Color("#ffe08a"), card_border, 4, 12)
	_apply_button_style_states(start, start_style)
	start.z_index = 202
	start.pressed.connect(_on_start_pressed)
	_attach_button_press_feedback(start)
	add_child(start)


func _make_card_button(card: Dictionary, is_selected: bool, is_clickable: bool, override_text := "") -> Button:
	var btn := Button.new()
	btn.set_meta("card_id", card["id"])
	btn.disabled = game_over or not is_clickable
	_configure_card_button_visual(btn, card, is_selected, override_text)
	return btn


func _configure_card_button_visual(btn: Button, card: Dictionary, is_selected: bool, override_text := "") -> void:
	_clear_generated_button_labels(btn)
	var display_text := override_text if override_text != "" else _card_text(card)
	btn.text = display_text
	btn.add_theme_font_size_override("font_size", _font_size_for_card_text(display_text, card["type"]))
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
	_apply_button_style_states(btn, _style(fill, border, 4, 10))
	if card["type"] == "category" and card["face_up"] and display_text != "":
		var lines := display_text.split("\n")
		var progress := "0/" + str(categories.get(card["category"], []).size())
		if lines.size() > 1:
			progress = String(lines[1])
		btn.text = ""
		_add_category_card_labels(btn, String(lines[0]), progress, Color("#544b4b"))


func _apply_button_style_states(btn: Button, style: StyleBoxFlat) -> void:
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("disabled", style)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _add_dashed_outline(parent: Control, outline_size: Vector2, color: Color, thickness: float, dash: float, gap: float, meta_name := "deck_dash") -> void:
	var right := outline_size.x - thickness
	var bottom := outline_size.y - thickness
	var x := 8.0
	while x < outline_size.x - 8.0:
		var dash_width: float = min(dash, outline_size.x - 8.0 - x)
		_add_dash(parent, Vector2(x, 0), Vector2(dash_width, thickness), color, meta_name)
		_add_dash(parent, Vector2(x, bottom), Vector2(dash_width, thickness), color, meta_name)
		x += dash + gap
	var y := 8.0
	while y < outline_size.y - 8.0:
		var dash_height: float = min(dash, outline_size.y - 8.0 - y)
		_add_dash(parent, Vector2(0, y), Vector2(thickness, dash_height), color, meta_name)
		_add_dash(parent, Vector2(right, y), Vector2(thickness, dash_height), color, meta_name)
		y += dash + gap


func _add_dash(parent: Control, pos: Vector2, dash_size: Vector2, color: Color, meta_name := "deck_dash") -> void:
	var line := ColorRect.new()
	line.set_meta(meta_name, true)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.color = color
	line.position = pos
	line.size = dash_size
	parent.add_child(line)


func _add_deck_count_labels(parent: Control) -> void:
	_add_generated_label(parent, "牌堆", Vector2(5, 26), Vector2(68, 24), 17, Color.WHITE)
	_add_generated_label(parent, "剩余" + str(deck.size()) + "张", Vector2(4, 52), Vector2(70, 22), 13, Color.WHITE)


func _add_category_card_labels(parent: Control, category_name: String, progress: String, color: Color) -> void:
	_add_generated_label(parent, category_name, Vector2(6, 20), Vector2(CARD_W - 12, 34), _font_size_for_card_text(category_name, "category"), color)
	_add_generated_label(parent, progress, Vector2(6, 57), Vector2(CARD_W - 12, 24), 16, color)


func _add_generated_label(parent: Control, text: String, pos: Vector2, label_size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.set_meta("generated_label", true)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = pos
	label.size = label_size
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _clear_generated_button_labels(parent: Control) -> void:
	for child in parent.get_children():
		if child.has_meta("generated_label"):
			child.free()


func _attach_button_press_feedback(btn: Button) -> void:
	btn.pivot_offset = btn.size * 0.5
	btn.button_down.connect(_on_button_feedback_down.bind(btn))
	btn.button_up.connect(_on_button_feedback_up.bind(btn))


func _on_button_feedback_down(btn: Button) -> void:
	if not is_instance_valid(btn) or btn.disabled:
		return
	_play_button_click_sfx()
	btn.pivot_offset = btn.size * 0.5
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(0.94, 0.94), 0.06)


func _on_button_feedback_up(btn: Button) -> void:
	if not is_instance_valid(btn):
		return
	btn.pivot_offset = btn.size * 0.5
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.12)


func _start_board_reveal_animation(btn: Button, card: Dictionary, selectable: bool, board_text: String) -> void:
	_play_card_flip_sfx()
	btn.disabled = true
	btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.pivot_offset = btn.size * 0.5
	btn.scale = Vector2.ONE
	var face_btn := _make_card_button(card, false, false, board_text)
	face_btn.set_meta("board_card_button", true)
	face_btn.disabled = true
	face_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face_btn.position = btn.position
	face_btn.size = btn.size
	face_btn.pivot_offset = face_btn.size * 0.5
	face_btn.scale = Vector2(0.08, 1.0)
	face_btn.z_index = btn.z_index + 1
	add_child(face_btn)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale:x", 0.08, 0.16)
	tween.tween_property(face_btn, "scale:x", 1.0, 0.16)
	tween.chain().tween_callback(_finish_board_reveal_animation.bind(int(card["id"]), btn, face_btn, card, board_text, selectable))


func _finish_board_reveal_animation(card_id: int, btn: Button, face_btn: Button, card: Dictionary, board_text: String, selectable: bool) -> void:
	revealing_board_cards.erase(card_id)
	if is_instance_valid(face_btn):
		face_btn.queue_free()
	if not is_instance_valid(btn):
		return
	_configure_card_button_visual(btn, card, false, board_text)
	btn.disabled = game_over or not selectable
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.scale = Vector2.ONE


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
		if not _draw_stack_has_card_id(card["id"]):
			draw_stack.append(card)
		return
	var target_pos := _draw_card_position(draw_stack.size() - 1)
	var back_card := card.duplicate()
	back_card["face_up"] = false
	var fly_card := _make_card_button(back_card, false, false)
	fly_card.disabled = true
	fly_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fly_card.position = Vector2(_column_x(3), DRAW_Y)
	fly_card.size = Vector2(CARD_W, CARD_H)
	fly_card.pivot_offset = fly_card.size * 0.5
	fly_card.scale = Vector2(0.98, 0.98)
	fly_card.rotation_degrees = 0.0
	fly_card.z_index = 120
	add_child(fly_card)
	draw_animation_nodes[card["id"]] = fly_card
	draw_animation_cards[card["id"]] = card
	draw_flights[card["id"]] = {
		"elapsed": 0.0,
		"move_elapsed": 0.0,
		"move_time": DRAW_ANIM_TIME,
		"start": fly_card.position,
		"target": target_pos,
		"flipped": false,
	}
	_retarget_draw_flights()


func _retarget_draw_flights() -> void:
	var hidden_card_ids: Array[int] = []
	var retarget_card_ids: Array[int] = []
	var retarget_targets := {}
	var retarget_starts := {}
	var common_move_time := 0.0
	for raw_card_id in draw_flights.keys():
		var card_id := int(raw_card_id)
		var stack_index := _draw_stack_index_for_card_id(card_id)
		if stack_index < 0 or not _draw_stack_index_is_visible(stack_index):
			hidden_card_ids.append(card_id)
			continue
		var next_target := _draw_card_position(stack_index)
		var flight: Dictionary = draw_flights[raw_card_id]
		var current_target: Vector2 = flight["target"]
		if current_target.distance_to(next_target) <= 0.1:
			continue
		var fly_card = draw_animation_nodes.get(card_id)
		if is_instance_valid(fly_card):
			var elapsed: float = float(flight.get("elapsed", 0.0))
			retarget_card_ids.append(card_id)
			retarget_targets[card_id] = next_target
			retarget_starts[card_id] = fly_card.position
			common_move_time = max(common_move_time, max(DRAW_RETARGET_TIME, DRAW_ANIM_TIME - elapsed))
		else:
			flight["target"] = next_target
	for card_id in retarget_card_ids:
		var flight: Dictionary = draw_flights[card_id]
		flight["start"] = retarget_starts[card_id]
		flight["move_elapsed"] = 0.0
		flight["move_time"] = common_move_time
		flight["target"] = retarget_targets[card_id]
	for card_id in hidden_card_ids:
		_discard_draw_animation(card_id)


func _draw_stack_index_is_visible(card_index: int) -> bool:
	return card_index >= max(0, draw_stack.size() - 3)


func _draw_stack_index_for_card_id(card_id: int) -> int:
	for i in range(draw_stack.size()):
		if int(draw_stack[i]["id"]) == card_id:
			return i
	return -1


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
		var move_time: float = max(0.001, float(flight.get("move_time", DRAW_ANIM_TIME)))
		flight["move_elapsed"] = min(move_time, float(flight.get("move_elapsed", 0.0)) + delta)
		var t: float = clamp(float(flight["elapsed"]) / DRAW_ANIM_TIME, 0.0, 1.0)
		var move_t: float = clamp(float(flight["move_elapsed"]) / move_time, 0.0, 1.0)
		var eased: float = 1.0 - pow(1.0 - t, 3.0)
		var move_eased: float = 1.0 - pow(1.0 - move_t, 3.0)
		var start: Vector2 = flight["start"]
		var target: Vector2 = flight["target"]
		fly_card.position = start.lerp(target, move_eased)
		if t >= CARD_FLIP_FACE_TIME and not bool(flight.get("flipped", false)):
			if draw_animation_cards.has(card_id):
				_configure_card_button_visual(fly_card, draw_animation_cards[card_id], false)
				fly_card.disabled = true
			flight["flipped"] = true
		var base_scale: float = lerp(0.98, 1.0, eased)
		var depth_scale: float = 1.0 + 0.08 * sin(t * PI)
		var flip_scale: float = _flip_scale_for_progress(t, CARD_FLIP_FACE_TIME)
		fly_card.scale = Vector2(base_scale * flip_scale * depth_scale, base_scale * depth_scale)
		fly_card.rotation_degrees = 0.0
		if t >= 1.0 and move_t >= 1.0:
			finished.append(card_id)
	for card_id in finished:
		draw_flights.erase(card_id)
		_finish_draw_card_animation(card_id)


func _finish_draw_card_animation(card_id: int) -> void:
	if draw_animation_cards.has(card_id):
		if not _draw_stack_has_card_id(card_id):
			draw_stack.append(draw_animation_cards[card_id])
	_discard_draw_animation(card_id)
	_render()


func _discard_draw_animation(card_id: int) -> void:
	draw_animation_cards.erase(card_id)
	animating_draw_cards.erase(card_id)
	draw_flights.erase(card_id)
	var fly_card = draw_animation_nodes.get(card_id)
	draw_animation_nodes.erase(card_id)
	if is_instance_valid(fly_card):
		fly_card.queue_free()


func _draw_stack_has_card_id(card_id: int) -> bool:
	for card in draw_stack:
		if int(card["id"]) == card_id:
			return true
	return false


func _spawn_wash_animation() -> void:
	var visible_count: int = min(3, draw_stack.size())
	if visible_count <= 0:
		_finish_wash_animation()
		return
	_clear_draw_animations_for_wash()
	wash_animation_nodes.clear()
	wash_animation_starts.clear()
	wash_flight.clear()
	var deck_button := _find_deck_button_control()
	if deck_button != null:
		deck_button.visible = false
		deck_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var visible_cards: Array = []
	for i in range(visible_count):
		var card_index: int = draw_stack.size() - visible_count + i
		visible_cards.append(draw_stack[card_index])
	_hide_drag_source_cards(visible_cards)

	for i in range(visible_count):
		var card_index: int = draw_stack.size() - visible_count + i
		var card: Dictionary = draw_stack[card_index]
		var node := _make_card_button(card, false, false)
		node.disabled = true
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.position = _draw_card_position(card_index)
		node.size = Vector2(CARD_W, CARD_H)
		node.pivot_offset = node.size * 0.5
		node.z_index = 125 + i
		add_child(node)
		wash_animation_nodes.append(node)
		wash_animation_starts.append(node.position)
	wash_animation_nodes[wash_animation_nodes.size() - 1].z_index = 135
	wash_flight = {
		"elapsed": 0.0,
		"target": Vector2(_column_x(3), DRAW_Y),
		"flipped": false,
	}


func _clear_draw_animations_for_wash() -> void:
	for raw_card_id in draw_animation_nodes.keys():
		_discard_draw_animation(int(raw_card_id))
	draw_flights.clear()
	draw_animation_cards.clear()
	animating_draw_cards.clear()


func _update_wash_flight(delta: float) -> void:
	if wash_flight.is_empty():
		return
	if wash_animation_nodes.is_empty():
		wash_flight.clear()
		_finish_wash_animation()
		return
	wash_flight["elapsed"] = float(wash_flight["elapsed"]) + delta
	var t: float = clamp(float(wash_flight["elapsed"]) / DRAW_ANIM_TIME, 0.0, 1.0)
	var eased: float = 1.0 - pow(1.0 - t, 3.0)
	var target: Vector2 = wash_flight["target"]
	for i in range(wash_animation_nodes.size()):
		var node := wash_animation_nodes[i]
		if not is_instance_valid(node):
			continue
		var start := wash_animation_starts[i]
		node.position = start.lerp(target, eased)
		node.rotation_degrees = 0.0
		if i < wash_animation_nodes.size() - 1:
			_update_wash_under_card_visual(node, t, eased)
		else:
			_update_wash_keeper_visual(node, t, eased)
	if t >= WASH_FLIP_FACE_TIME and not bool(wash_flight.get("flipped", false)):
		for node in wash_animation_nodes:
			_set_wash_card_back(node)
		wash_flight["flipped"] = true
	if t >= 1.0:
		wash_flight.clear()
		_finish_wash_animation()


func _update_wash_keeper_visual(node: Control, t: float, eased: float) -> void:
	var base_scale: float = lerp(0.98, 1.0, eased)
	var depth_scale: float = 1.0 + 0.08 * sin(t * PI)
	var flip_scale: float = _flip_scale_for_progress(t, WASH_FLIP_FACE_TIME)
	node.scale = Vector2(base_scale * flip_scale * depth_scale, base_scale * depth_scale)
	node.rotation_degrees = 0.0


func _update_wash_under_card_visual(node: Control, t: float, eased: float) -> void:
	var under_scale: float = lerp(1.0, 0.96, eased)
	var flip_scale: float = _flip_scale_for_progress(t, WASH_FLIP_FACE_TIME)
	node.scale = Vector2(under_scale * flip_scale, under_scale)
	node.rotation_degrees = 0.0


func _flip_scale_for_progress(t: float, flip_face_time: float) -> float:
	if t < flip_face_time:
		return max(0.08, cos((t / flip_face_time) * PI * 0.5))
	var open_t: float = (t - flip_face_time) / (1.0 - flip_face_time)
	return max(0.08, sin(open_t * PI * 0.5))


func _set_wash_card_back(node: Control) -> void:
	if not is_instance_valid(node) or draw_stack.is_empty():
		return
	var back_card: Dictionary = draw_stack[draw_stack.size() - 1].duplicate()
	back_card["face_up"] = false
	_configure_card_button_visual(node as Button, back_card, false)
	(node as Button).disabled = true


func _finish_wash_animation() -> void:
	for node in wash_animation_nodes:
		if is_instance_valid(node):
			node.queue_free()
	wash_animation_nodes.clear()
	wash_animation_starts.clear()
	wash_flight.clear()
	for card in draw_stack:
		card["face_up"] = false
	deck = draw_stack.duplicate()
	deck.shuffle()
	draw_stack.clear()
	deck_animation_busy = false
	_consume_step("洗牌完成")


func _find_deck_button_control() -> Control:
	return _find_deck_button_control_in_node(self)


func _find_deck_button_control_in_node(node: Node) -> Control:
	if node is Control and node.has_meta("deck_button"):
		return node
	for child in node.get_children():
		var found := _find_deck_button_control_in_node(child)
		if found != null:
			return found
	return null


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
		return "牌堆\n剩余" + str(deck.size()) + "张"
	if draw_stack.size() > 0:
		return "点击洗牌"
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
	return Rect2(Vector2(_column_x(col_idx), BOARD_Y), Vector2(CARD_W, column_height + BOARD_DROP_EXTRA_BOTTOM))


func _deck_rect() -> Rect2:
	return Rect2(Vector2(_column_x(3), DRAW_Y), Vector2(78, 104))


func _on_deck_pressed() -> void:
	if menu_active:
		return
	_handle_deck_pressed()


func _on_deck_gui_input(event: InputEvent) -> void:
	if menu_active or game_over:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_deck_gui_pressed()
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		_handle_deck_gui_pressed()
		accept_event()


func _handle_deck_gui_pressed() -> void:
	var current_frame := Engine.get_process_frames()
	if last_deck_gui_press_frame == current_frame:
		return
	last_deck_gui_press_frame = current_frame
	_handle_deck_pressed()


func _handle_deck_pressed() -> void:
	if game_over or deck_animation_busy:
		return
	selected.clear()
	if deck.size() > 0:
		_play_card_flip_sfx()
		var card: Dictionary = deck.pop_back()
		card["face_up"] = true
		steps_left -= 1
		status_text = "翻出：" + card["name"]
		draw_stack.append(card)
		_check_end_state()
		if is_inside_tree():
			animating_draw_cards[card["id"]] = true
			_render()
			_spawn_draw_card_animation(card)
		return
	elif draw_stack.size() > 0:
		_play_card_flip_sfx()
		if is_inside_tree():
			deck_animation_busy = true
			_spawn_wash_animation()
			return
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
	if menu_active or game_over:
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
	if menu_active or game_over:
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


func _start_new_round(message: String) -> void:
	if round_transition_active:
		return
	pending_round_message = message
	_play_round_close_transition()


func _setup_new_round(message: String) -> void:
	_clear_transient_interaction_state(false)
	deck.clear()
	draw_stack.clear()
	columns.clear()
	active_categories.clear()
	active_order.clear()
	selected.clear()
	previous_card_positions.clear()
	next_card_id = 1
	steps_left = STARTING_STEPS
	game_over = false
	menu_active = false
	status_text = message
	_init_level()
	_render()


func _play_round_close_transition() -> void:
	if not is_inside_tree():
		_setup_new_round(pending_round_message)
		return
	_clear_round_transition()
	round_transition_active = true
	var viewport_size: Vector2 = get_viewport_rect().size
	var half_height: float = ceil(viewport_size.y * 0.5)

	var overlay := Control.new()
	overlay.set_meta("round_transition_overlay", true)
	overlay.position = Vector2.ZERO
	overlay.size = viewport_size
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 260
	add_child(overlay)
	round_transition_overlay = overlay

	var top := ColorRect.new()
	top.set_meta("round_transition_top", true)
	top.color = curtain_color
	top.position = Vector2(0.0, -half_height - 2.0)
	top.size = Vector2(viewport_size.x, half_height + 2.0)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(top)
	_add_round_transition_seam(top, "round_transition_top_shadow", true, viewport_size.x)

	var bottom := ColorRect.new()
	bottom.set_meta("round_transition_bottom", true)
	bottom.color = curtain_color
	bottom.position = Vector2(0.0, viewport_size.y)
	bottom.size = Vector2(viewport_size.x, viewport_size.y - half_height + 2.0)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(bottom)
	_add_round_transition_seam(bottom, "round_transition_bottom_shadow", false, viewport_size.x)

	_kill_round_transition_tween()
	var tween := create_tween()
	round_transition_tween = tween
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(top, "position:y", 0.0, ROUND_TRANSITION_CLOSE_TIME)
	tween.tween_property(bottom, "position:y", half_height - 1.0, ROUND_TRANSITION_CLOSE_TIME)
	tween.chain().tween_callback(_finish_round_close_transition.bind(overlay))


func _finish_round_close_transition(overlay: Control) -> void:
	_kill_round_transition_tween()
	if not is_instance_valid(overlay):
		round_transition_active = false
		return
	_setup_new_round(pending_round_message)
	_start_round_transition_hold(overlay)


func _start_round_transition_hold(overlay: Control) -> void:
	if not is_instance_valid(overlay):
		round_transition_active = false
		return
	_kill_round_transition_tween()
	var tween := create_tween()
	round_transition_tween = tween
	tween.tween_interval(ROUND_TRANSITION_HOLD_TIME)
	tween.tween_callback(_play_round_open_transition.bind(overlay))


func _add_round_transition_seam(parent: Control, meta_name: String, at_bottom: bool, width: float) -> void:
	var seam_y := parent.size.y - ROUND_TRANSITION_SEAM_H if at_bottom else 0.0
	var shade := ColorRect.new()
	shade.set_meta(meta_name, true)
	shade.color = Color(0.16, 0.24, 0.13, 0.16)
	shade.position = Vector2(0.0, seam_y + (ROUND_TRANSITION_SEAM_H - 2.0 if at_bottom else 0.0))
	shade.size = Vector2(width, 2.0)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(shade)

	var highlight := ColorRect.new()
	highlight.color = Color(1.0, 1.0, 1.0, 0.10)
	highlight.position = Vector2(0.0, seam_y if at_bottom else seam_y + 3.0)
	highlight.size = Vector2(width, 1.0)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(highlight)


func _play_round_open_transition(overlay: Control) -> void:
	if not is_instance_valid(overlay):
		round_transition_active = false
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var top := _find_transition_panel(overlay, "round_transition_top")
	var bottom := _find_transition_panel(overlay, "round_transition_bottom")
	if top == null or bottom == null:
		_finish_round_open_transition(overlay)
		return
	_kill_round_transition_tween()
	var tween := create_tween()
	round_transition_tween = tween
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(top, "position:y", -top.size.y, ROUND_TRANSITION_OPEN_TIME)
	tween.tween_property(bottom, "position:y", viewport_size.y, ROUND_TRANSITION_OPEN_TIME)
	tween.chain().tween_callback(_finish_round_open_transition.bind(overlay))


func _finish_round_open_transition(overlay: Control) -> void:
	_kill_round_transition_tween()
	if is_instance_valid(overlay):
		overlay.queue_free()
	if round_transition_overlay == overlay:
		round_transition_overlay = null
	round_transition_active = false
	pending_round_message = ""


func _find_transition_panel(node: Node, meta_name: String) -> ColorRect:
	for child in node.get_children():
		if child is ColorRect and child.has_meta(meta_name):
			return child
		var nested := _find_transition_panel(child, meta_name)
		if nested != null:
			return nested
	return null


func _clear_round_transition() -> void:
	_kill_round_transition_tween()
	if is_instance_valid(round_transition_overlay):
		round_transition_overlay.queue_free()
	round_transition_overlay = null
	round_transition_active = false
	pending_round_message = ""


func _kill_round_transition_tween() -> void:
	if is_instance_valid(round_transition_tween):
		round_transition_tween.kill()
	round_transition_tween = null


func _on_restart_pressed() -> void:
	_start_new_round("点击牌堆开始")


func _on_home_pressed() -> void:
	_clear_transient_interaction_state()
	menu_active = true
	game_over = false
	selected.clear()
	_render()


func _on_start_pressed() -> void:
	_start_new_round("开始游戏")


func _clear_transient_interaction_state(clear_transition := true) -> void:
	if clear_transition:
		_clear_round_transition()
	drag_candidate.clear()
	selected.clear()
	pending_spawn_positions.clear()
	pending_draw_animations.clear()
	animating_draw_cards.clear()
	revealing_board_cards.clear()
	suppress_next_move_animations.clear()
	deck_animation_busy = false
	draw_flights.clear()
	draw_animation_cards.clear()
	wash_flight.clear()
	wash_animation_starts.clear()
	for node in draw_animation_nodes.values():
		if is_instance_valid(node):
			node.queue_free()
	draw_animation_nodes.clear()
	for node in wash_animation_nodes:
		if is_instance_valid(node):
			node.queue_free()
	wash_animation_nodes.clear()
	if is_instance_valid(drag_preview):
		drag_preview.queue_free()
	drag_preview = null
	if is_instance_valid(returning_drag_preview):
		returning_drag_preview.queue_free()
	returning_drag_preview = null
	if is_instance_valid(absorbing_drag_preview):
		absorbing_drag_preview.queue_free()
	absorbing_drag_preview = null
	pending_absorb_slot = -1
	completing_category_slot = -1
	completing_category_name = ""


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
	var completed := _collect_words(category, cards, true)
	if completed:
		selected["complete_category_slot"] = slot_idx
		selected["complete_category_name"] = category
	status_text = "类别进入 3 区：" + category
	return true


func _remove_selected_from_source() -> void:
	if selected.get("source") == "draw":
		var old_draw_size := draw_stack.size()
		var removed_index: int = selected["index"]
		draw_stack.remove_at(selected["index"])
		_prepare_draw_refill_animation(old_draw_size, removed_index)
	elif selected.get("source") == "board":
		var col_idx: int = selected["col"]
		var start: int = selected["start"]
		var column: Array = columns[col_idx]
		while column.size() > start:
			column.remove_at(column.size() - 1)
			_reveal_bottom_card(col_idx)


func _prepare_draw_refill_animation(old_draw_size: int, removed_index: int) -> void:
	if removed_index != old_draw_size - 1:
		return
	var new_draw_size := draw_stack.size()
	if old_draw_size <= 3 or new_draw_size < 3:
		return
	var new_first_visible_index := new_draw_size - 3
	if new_first_visible_index < 0 or new_first_visible_index >= draw_stack.size():
		return
	var refill_card: Dictionary = draw_stack[new_first_visible_index]
	var target_pos := _draw_card_position_for_size(new_first_visible_index, new_draw_size)
	previous_card_positions[refill_card["id"]] = target_pos + Vector2(18.0, 0.0)


func _reveal_bottom_card(col_idx: int) -> void:
	var column: Array = columns[col_idx]
	if column.is_empty():
		return
	var bottom: Dictionary = column[column.size() - 1]
	if not bottom["face_up"]:
		bottom["face_up"] = true
		if is_inside_tree():
			revealing_board_cards[bottom["id"]] = true


func _collect_words(category: String, cards: Array, defer_completion := false) -> bool:
	var state: Dictionary = active_categories[category]
	var collected: Array = state["collected"]
	for card in cards:
		if card["type"] == "word" and card["category"] == category and not collected.has(card["name"]):
			collected.append(card["name"])
	if collected.size() >= categories[category].size():
		status_text = category + " 已集齐并移除"
		if not defer_completion:
			active_categories.erase(category)
			_clear_category_slot(category)
		return true
	return false


func _after_successful_move() -> void:
	if selected.has("absorb_target_position") and drag_preview != null and is_instance_valid(drag_preview):
		if selected.get("source") == "draw":
			_refresh_draw_area_only()
		elif selected.get("source") == "board":
			_refresh_board_area_only()
		_animate_category_absorb()
		return
	if selected.has("complete_category_slot"):
		_animate_completed_category_slot()
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


func _animate_completed_category_slot() -> void:
	if drag_preview != null and is_instance_valid(drag_preview):
		drag_preview.queue_free()
		drag_preview = null
	_suppress_selected_move_animations()
	completing_category_slot = int(selected.get("complete_category_slot", -1))
	completing_category_name = String(selected.get("complete_category_name", ""))
	status_text = completing_category_name + " 已集齐并移除"
	_render()
	if _pulse_absorb_category_slot(completing_category_slot, _finish_completed_category_pulse):
		return
	_finish_completed_category_pulse()


func _finish_completed_category_pulse() -> void:
	var category_button := _find_category_slot_button(completing_category_slot)
	if category_button != null:
		category_button.pivot_offset = category_button.size * 0.5
		var tween := create_tween()
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(category_button, "scale", Vector2(0.84, 0.84), 0.12)
		tween.tween_property(category_button, "modulate:a", 0.0, 0.12)
		tween.chain().tween_callback(_finish_completed_category_disappear)
		return
	_finish_completed_category_disappear()


func _finish_completed_category_disappear() -> void:
	if completing_category_name != "":
		active_categories.erase(completing_category_name)
		_clear_category_slot(completing_category_name)
	completing_category_slot = -1
	completing_category_name = ""
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
	if not _has_any_available_step():
		game_over = true
		status_text = "无法移动"


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


func _has_any_available_step() -> bool:
	if _has_pending_card_motion():
		return true
	if not deck.is_empty():
		return true
	if not draw_stack.is_empty():
		return true
	return _has_any_legal_move()


func _has_pending_card_motion() -> bool:
	return not draw_flights.is_empty() \
		or not draw_animation_cards.is_empty() \
		or not wash_flight.is_empty() \
		or not wash_animation_nodes.is_empty() \
		or absorbing_drag_preview != null \
		or returning_drag_preview != null \
		or drag_preview != null \
		or completing_category_name != ""


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
