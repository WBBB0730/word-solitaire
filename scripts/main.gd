## 手机端卡牌分类游戏主场景。
##
## 本脚本负责实时场景状态、界面渲染、动画和拖拽输入。
## 类别抽样、求解器和音频播放拆到辅助脚本，主脚本只保留强 Godot 节点树耦合的编排逻辑。
extends Control

const CategorySelectorScript := preload("res://scripts/category_selector.gd")
const CategoryLibraryScript := preload("res://scripts/category_library.gd")
const DealSolverScript := preload("res://scripts/deal_solver.gd")
const GameAudioScript := preload("res://scripts/game_audio.gd")
const AdServiceScript := preload("res://scripts/ads/ad_service.gd")
const PropSystemScript := preload("res://scripts/prop_system.gd")
const TutorialControllerScript := preload("res://scripts/tutorial_controller.gd")
const TutorialOverlayScript := preload("res://scripts/tutorial_overlay.gd")
const PropHintTexture := preload("res://assets/props/prop_hint.png")
const PropUndoTexture := preload("res://assets/props/prop_undo.png")
const AdPlayTexture := preload("res://assets/ui/ad_play.svg")

const GAME_W := 720.0
const GAME_H := 1280.0
const UI_SCALE := 1.8
const CARD_W := 150.0
const CARD_H := 200.0
const STACK_STEP := 46.0
const BOARD_DROP_EXTRA_BOTTOM := 180.0
const COL_GAP := 24.0
const DRAW_Y := 54.0
const CATEGORY_Y := 330.0
const BOARD_Y := 570.0
const DRAW_STACK_SPREAD := 32.0
const TOP_CONTROL_X := 23.0
const TOP_CONTROL_Y := 16.0
const TOP_BUTTON_W := 96.0
const TOP_BUTTON_H := 52.0
const TOP_BUTTON_GAP := 14.0
const STEPS_LABEL_Y := 88.0
const PROP_BUTTON_W := 86.0
const PROP_BUTTON_H := 86.0
const PROP_BUTTON_GAP := 42.0
const PROP_BUTTON_Y := 1128.0
const PROP_BADGE_SIZE := 36.0
const PROP_DISABLED_COLOR := Color("#d6c990")
const SETTINGS_PANEL_W := 480.0
const SETTINGS_PANEL_H := 480.0
const SETTINGS_ACTION_W := 300.0
const SETTINGS_ACTION_H := 66.0
const SETTINGS_ACTION_GAP := 18.0
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
const EXTRA_STEPS_AD_REWARD := 20
const AD_CHEAT_SEQUENCE := [
	KEY_UP,
	KEY_UP,
	KEY_DOWN,
	KEY_DOWN,
	KEY_LEFT,
	KEY_RIGHT,
	KEY_LEFT,
	KEY_RIGHT,
	KEY_B,
	KEY_A,
	KEY_B,
	KEY_A,
]
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
const USER_SETTINGS_PATH := "user://settings.cfg"
const USER_SETTINGS_SECTION := "audio"
const PROP_SETTINGS_SECTION := "props"
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

## 总类别牌库。每局会从这里抽取一部分类别。
var category_pool := CategoryLibraryScript.get_category_pool()
## 手写类别冲突组。同组类别不会被抽进同一局。
var category_conflict_groups := CategoryLibraryScript.get_category_conflict_groups()
## 用户配置文件路径。测试可替换为临时路径。
var user_settings_path := USER_SETTINGS_PATH

## 当前局选中的类别集合。
var categories := {}
## 当前局词语到类别的反向索引。
var word_to_category := {}
## 2 区未翻开的牌堆。
var deck: Array = []
## 1 区已翻开的牌堆，只有最上方一张可移动。
var draw_stack: Array = []
## 4 区四列牌，从上到下保存卡牌字典。
var columns: Array = []
## 3 区已激活类别及其已收集词语。
var active_categories := {}
## 3 区槽位顺序。类别完成后保留空字符串，不向左补位。
var active_order: Array[String] = []
## 当前拖拽来源选择数据。
var selected := {}
## 独立开始菜单是否正在显示。
var menu_active := true
## 游戏内设置弹窗是否打开。
var settings_menu_open := false
## 背景音乐是否启用。
var music_enabled := true
## 所有短音效是否启用。
var sfx_enabled := true
## 剩余步数。抽牌和洗牌都消耗一步。
var steps_left := STARTING_STEPS
## 递增卡牌编号，用于动画追踪和求解器状态键。
var next_card_id := 1
## 胜利或失败弹窗出现后阻止继续输入。
var game_over := false
## 当前状态文案，用于结束弹窗和调试。
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
## 音频辅助对象。下面的公开音频字段会同步它，方便测试和调试。
var audio_manager: RefCounted
## 广告服务入口。主逻辑只通过它请求奖励，不直接依赖具体广告 SDK。
var ad_service: RefCounted
## 局内道具辅助对象。管理永久库存、撤回快照和提示搜索。
var prop_system: RefCounted
## 新手教学控制器。固定教学关、步骤白名单和完成状态保存在独立脚本中。
var tutorial_controller: RefCounted
## 新手教学视觉层。负责手势和高亮，不参与规则判断。
var tutorial_overlay: RefCounted
## 是否已经完成过教学。首次为 false 时，开始游戏会进入教学关。
var tutorial_completed := false
## 成功移动后延迟到动画完成时再通知教程推进。
var pending_tutorial_action := {}
var music_player: AudioStreamPlayer
var card_flip_sfx_stream: AudioStream
var button_click_sfx_stream: AudioStream
var sfx_players: Array = []
var button_sfx_players: Array = []
var next_sfx_player := 0
var next_button_sfx_player := 0
var audio_initialized := false
## 当前随机牌局求解验证的诊断信息。
var last_solver_attempts := 0
var last_solver_steps := 0
var last_solver_states := 0
var last_solver_found := false
## 本局是否已经成功领取过广告加步数奖励。
var extra_steps_ad_used := false
## 正在等待回调的激励广告位。非空时局内输入会暂停。
var pending_rewarded_placement := ""
## 编辑器广告后门秘籍的当前匹配位置。
var ad_cheat_index := 0
## 是否允许运行时响应视口尺寸变化。
var layout_resize_ready := false
## 尺寸变化会合并到下一帧刷新，避免拖拽窗口时连续重建 UI。
var layout_resize_refresh_pending := false
## 上一次完成布局刷新时的视口尺寸。
var last_layout_viewport_size := Vector2.ZERO
## 上一次完成布局刷新时的 safe area。
var last_layout_safe_rect := Rect2()

var bg_color := Color("#a9d78e")
var curtain_color := Color("#94c87c")
var card_color := Color("#fbfbf4")
var category_color := Color("#ffe08a")
var card_border := Color("#161616")
var back_color := Color("#4d9be8")
var slot_color := Color(1.0, 1.0, 1.0, 0.20)
var category_empty_slot_color := Color("#f6d86a", 0.42)


## Godot 生命周期入口：初始化音频、生成首局并渲染。
func _ready() -> void:
	_configure_root_layout()
	_bind_viewport_resize_signal()
	_init_props()
	_load_user_settings()
	_init_audio()
	_init_ads()
	_init_tutorial()
	randomize()
	_init_level()
	_render()
	_remember_layout_metrics()
	layout_resize_ready = true


## 捕捉 Control 自身尺寸变化，作为 viewport 信号之外的兜底。
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_request_layout_refresh()


## 处理全局拖拽过程中的移动和松手事件。
func _input(event: InputEvent) -> void:
	_handle_ad_cheat_input(event)
	if _ad_is_showing():
		return
	if round_transition_active:
		return
	if settings_menu_open:
		return
	if menu_active:
		return
	if drag_candidate.is_empty():
		return
	if event is InputEventMouseMotion:
		_update_drag(event.position, event.global_position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_finish_drag(event.global_position)


## 推进持续中的抽牌飞行动画和洗牌动画。
func _process(delta: float) -> void:
	_update_draw_flights(delta)
	_update_wash_flight(delta)


## 初始化音频辅助对象。
func _init_audio() -> void:
	if audio_manager == null:
		audio_manager = GameAudioScript.new(self)
	audio_manager.init_audio()
	_sync_audio_enabled_state()


## 初始化广告服务，并监听激励广告结果。
func _init_ads() -> void:
	if ad_service == null:
		ad_service = AdServiceScript.new(self)
		ad_service.rewarded_ad_completed.connect(_on_rewarded_ad_completed)
		ad_service.rewarded_ad_failed.connect(_on_rewarded_ad_failed)


## 初始化局内道具系统。
func _init_props() -> void:
	if prop_system == null:
		prop_system = PropSystemScript.new(self)


## 初始化新手教学控制器。
func _init_tutorial() -> void:
	if tutorial_controller == null:
		tutorial_controller = TutorialControllerScript.new(self)
	if tutorial_overlay == null:
		tutorial_overlay = TutorialOverlayScript.new(self)


## 处理编辑器专用广告后门秘籍：上上下下左右左右 B A B A。
func _handle_ad_cheat_input(event: InputEvent) -> void:
	if not OS.has_feature("editor"):
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var keycode: int = int(event.keycode)
	if keycode == AD_CHEAT_SEQUENCE[ad_cheat_index]:
		ad_cheat_index += 1
		if ad_cheat_index >= AD_CHEAT_SEQUENCE.size():
			ad_cheat_index = 0
			_toggle_editor_ad_bypass()
		return
	ad_cheat_index = 1 if keycode == AD_CHEAT_SEQUENCE[0] else 0


## 切换编辑器广告后门，并用状态文案给轻量反馈。
func _toggle_editor_ad_bypass() -> void:
	if ad_service == null:
		return
	var enabled: bool = ad_service.toggle_editor_bypass()
	status_text = "广告后门：" + ("开" if enabled else "关")
	_render()


## 当前是否处于教学关。
func _tutorial_active() -> bool:
	return tutorial_controller != null and tutorial_controller.is_active()


## 兼容旧测试入口：设置音频流循环。
func _set_audio_stream_loop(stream: AudioStream, enabled: bool) -> void:
	GameAudioScript.set_audio_stream_loop(stream, enabled)


## 播放背景音乐，通常由延迟回调触发。
func _play_background_music() -> void:
	if music_enabled and audio_manager != null:
		audio_manager.play_background_music()


## 让根 Control 始终铺满当前 viewport，确保 NOTIFICATION_RESIZED 能稳定触发。
func _configure_root_layout() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0


## 监听运行时窗口/屏幕尺寸变化，手机旋转和桌面改窗口都会走这里。
func _bind_viewport_resize_signal() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	if not viewport.size_changed.is_connected(_on_viewport_size_changed):
		viewport.size_changed.connect(_on_viewport_size_changed)


## Viewport 尺寸变化回调。
func _on_viewport_size_changed() -> void:
	_request_layout_refresh()


## 请求在下一帧刷新布局，避免同一帧内重复重建控件。
func _request_layout_refresh() -> void:
	if not layout_resize_ready or not is_inside_tree():
		return
	if layout_resize_refresh_pending:
		return
	layout_resize_refresh_pending = true
	call_deferred("_apply_pending_layout_refresh")


## 真正执行一次响应式布局刷新；只重排界面，不重新生成牌局。
func _apply_pending_layout_refresh() -> void:
	layout_resize_refresh_pending = false
	if not layout_resize_ready or not is_inside_tree():
		return
	if not _layout_metrics_changed():
		return
	_cancel_drag_for_layout_refresh()
	if round_transition_active:
		_resize_round_transition_overlay()
	_render()
	_remember_layout_metrics()


## 判断 viewport 或 safe area 是否真的变了。
func _layout_metrics_changed() -> bool:
	return get_viewport_rect().size != last_layout_viewport_size or _safe_viewport_rect() != last_layout_safe_rect


## 记录刚刚完成渲染时使用的布局指标。
func _remember_layout_metrics() -> void:
	if not is_inside_tree():
		return
	last_layout_viewport_size = get_viewport_rect().size
	last_layout_safe_rect = _safe_viewport_rect()


## 尺寸变化时取消正在拖拽的手牌，避免源牌隐藏在旧位置。
func _cancel_drag_for_layout_refresh() -> void:
	drag_candidate.clear()
	selected.clear()
	if is_instance_valid(drag_preview):
		drag_preview.queue_free()
	drag_preview = null


## 运行时改屏幕尺寸时，让转场幕布覆盖新的 viewport。
func _resize_round_transition_overlay() -> void:
	if not is_instance_valid(round_transition_overlay):
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var half_height: float = ceil(viewport_size.y * 0.5)
	round_transition_overlay.position = Vector2.ZERO
	round_transition_overlay.size = viewport_size
	var top := _find_transition_panel(round_transition_overlay, "round_transition_top")
	if top != null:
		top.size = Vector2(viewport_size.x, half_height + 2.0)
	var bottom := _find_transition_panel(round_transition_overlay, "round_transition_bottom")
	if bottom != null:
		bottom.size = Vector2(viewport_size.x, viewport_size.y - half_height + 2.0)


## 播放翻牌/洗牌音效。
func _play_card_flip_sfx() -> void:
	if sfx_enabled and audio_manager != null:
		audio_manager.play_card_flip_sfx()


## 播放普通按钮点击音效。
func _play_button_click_sfx() -> void:
	if sfx_enabled and audio_manager != null:
		audio_manager.play_button_click_sfx()


## 兼容旧测试入口：计算平衡后的音量。
func _audio_balanced_volume_db(group_volume_db: float, asset_trim_db: float) -> float:
	return GameAudioScript.balanced_volume_db(group_volume_db, asset_trim_db)


## 生成一局经过求解器验证的牌局；如果所有尝试失败，则回退到默认步数。
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


## 为单次求解尝试构造一个随机发牌候选。
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


## 将求解器步数换算成玩家看到的步数预算。
func _steps_for_solution(solution_steps: int) -> int:
	var padding: int = max(SOLVER_STEP_PADDING_MIN, int(ceil(float(solution_steps) * SOLVER_STEP_PADDING_RATIO)))
	return solution_steps + padding


## 委托纯规则辅助脚本选择当前局类别。
func _select_categories_for_game() -> Dictionary:
	return CategorySelectorScript.select_categories_for_game(
		category_pool,
		CATEGORIES_PER_GAME,
		MAX_EIGHT_WORD_CATEGORIES,
		MAX_SEVEN_WORD_CATEGORIES,
		category_conflict_groups
	)


## 兼容测试和调试脚本的薄包装。
func _select_category_candidate() -> Dictionary:
	return CategorySelectorScript._select_category_candidate(
		category_pool,
		CATEGORIES_PER_GAME,
		MAX_EIGHT_WORD_CATEGORIES,
		MAX_SEVEN_WORD_CATEGORIES,
		category_conflict_groups
	)


## 兼容测试入口：检查类别长度限制。
func _category_length_is_available(category: String, selected_categories: Dictionary) -> bool:
	return CategorySelectorScript.category_length_is_available(
		category,
		category_pool,
		selected_categories,
		MAX_EIGHT_WORD_CATEGORIES,
		MAX_SEVEN_WORD_CATEGORIES
	)


## 兼容测试入口：统计指定长度类别数量。
func _selected_category_length_count(selected_categories: Dictionary, length: int) -> int:
	return CategorySelectorScript.selected_category_length_count(selected_categories, length)


## 兼容测试入口：统计类别长度多样性。
func _word_count_variety(selection: Dictionary) -> int:
	return CategorySelectorScript.word_count_variety(selection)


## 兼容测试入口：检查类别词语是否与已选类别重复。
func _category_words_are_available(category: String, used_words: Dictionary) -> bool:
	return CategorySelectorScript.category_words_are_available(category, category_pool, used_words)


## 兼容测试入口：检查类别是否会产生跨类别混淆标记。
func _category_conflict_tokens_are_available(category: String, used_conflict_tokens: Dictionary) -> bool:
	return CategorySelectorScript.category_conflict_tokens_are_available(category, category_pool, used_conflict_tokens)


## 兼容测试入口：检查类别是否命中手写冲突组。
func _category_conflict_groups_are_available(category: String, blocked_categories: Dictionary) -> bool:
	return CategorySelectorScript.category_conflict_groups_are_available(category, blocked_categories)


## 兼容测试入口：记录已选类别词语和混淆标记。
func _mark_category_words_used(category: String, used_words: Dictionary, used_conflict_tokens: Dictionary, blocked_categories := {}) -> void:
	CategorySelectorScript.mark_category_words_used(category, category_pool, used_words, used_conflict_tokens, category_conflict_groups, blocked_categories)


## 兼容测试入口：提取词语混淆标记。
func _word_conflict_tokens(word: String) -> Array[String]:
	return CategorySelectorScript.word_conflict_tokens(word)


## 兼容测试入口：判断混淆标记是否过于宽泛。
func _is_weak_conflict_token(token: String) -> bool:
	return CategorySelectorScript.is_weak_conflict_token(token)


## 为当前局类别创建类别牌和所有词语牌。
func _build_full_deck() -> Array:
	var all_cards: Array = []
	for category in categories.keys():
		all_cards.append(_category(category, false))
		for word in categories[category]:
			all_cards.append(_word(word, false))
	return all_cards


## 向 4 区发 24 张牌，剩余牌进入 2 区牌堆。
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


## 用最少的随机交换满足开局可玩性约束，尽量保持整体随机性。
func _ensure_bottom_visible_opening_mix() -> void:
	_ensure_bottom_visible_category()
	_ensure_bottom_visible_words(2)


## 确保开局四列底牌里至少有一张类别牌。
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


## 确保开局四列底牌里至少有指定数量的词语牌。
func _ensure_bottom_visible_words(min_word_count: int) -> void:
	while _bottom_visible_count("word") < min_word_count:
		var bottom_categories := _bottom_visible_locations("category")
		var hidden_words := _hidden_card_locations("word")
		if bottom_categories.is_empty() or hidden_words.is_empty():
			return
		var target: Dictionary = bottom_categories[randi_range(0, bottom_categories.size() - 1)]
		var source: Dictionary = hidden_words[randi_range(0, hidden_words.size() - 1)]
		_swap_location_cards(target, source)


## 判断当前四列底牌是否已有类别牌。
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


## 返回四列底牌中指定类型卡牌的位置。
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


## 返回被盖住的指定类型卡牌位置，用于开局交换。
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


## 交换两个牌局位置上的卡牌。
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


## 兼容测试入口：运行随机深度优先求解器。
func _solve_current_deal(max_solution_steps := SOLVER_MAX_SOLUTION_STEPS) -> Dictionary:
	return DealSolverScript.new(self).solve(max_solution_steps)


## 兼容测试入口：运行单次深度优先求解样本。
func _solve_current_deal_dfs(max_solution_steps := SOLVER_MAX_SOLUTION_STEPS, state_budget := SOLVER_MAX_STATES_PER_DEAL) -> Dictionary:
	return DealSolverScript.new(self).solve_dfs(max_solution_steps, state_budget)


## 创建词语牌数据字典。
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


## 创建类别牌数据字典。
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


## 根据当前场景状态重建完整界面。
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
		if settings_menu_open:
			_render_settings_menu()
		previous_card_positions = next_card_positions
		return

	_render_top_controls()
	_render_draw_area(next_card_positions)
	_render_deck_area()
	_render_category_area()
	_render_board_area(next_card_positions)
	_render_prop_area()

	if game_over:
		_render_overlay()
	if settings_menu_open:
		_render_settings_menu()
	if _tutorial_active():
		_render_tutorial_guidance()
	elif prop_system != null and not prop_system.hint_guidance().is_empty():
		_render_prop_hint_guidance()

	previous_card_positions = next_card_positions


## 重绘时保留音频节点和正在播放动画的临时节点。
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


## 渲染 1 区，包括向左展开的可见翻牌堆。
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


## 渲染 2 区牌堆、洗牌入口或空虚线框。
func _render_deck_area() -> void:
	var btn := Control.new()
	btn.set_meta("deck_button", true)
	btn.position = Vector2(_column_x(3), _layout_y(DRAW_Y))
	btn.size = Vector2(CARD_W, CARD_H)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var has_deck_cards := deck.size() > 0
	var deck_style := _style(back_color, Color.WHITE, 6, 18) if has_deck_cards else _style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 18)
	btn.gui_input.connect(_on_deck_gui_input)
	var surface := Panel.new()
	surface.set_meta("deck_surface", true)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.position = Vector2.ZERO
	surface.size = btn.size
	surface.add_theme_stylebox_override("panel", deck_style)
	btn.add_child(surface)
	if not has_deck_cards:
		_add_dashed_outline(btn, btn.size, Color(1, 1, 1, 0.62), 5.0, 18.0, 12.0)
		_add_generated_label(btn, _deck_button_text(), Vector2(8, 76), Vector2(CARD_W - 16, 42), _ui_font(16), Color(1, 1, 1, 0.72))
	else:
		_add_deck_count_labels(btn)
	add_child(btn)


## 渲染左上角菜单入口和剩余步数。
func _render_top_controls() -> void:
	var origin := _play_area_origin()
	var menu := _make_top_button("菜单", origin + Vector2(TOP_CONTROL_X, TOP_CONTROL_Y), "settings_button")
	menu.pressed.connect(_on_settings_pressed)
	add_child(menu)

	_add_label("剩余步数：" + str(steps_left), origin + Vector2(TOP_CONTROL_X, STEPS_LABEL_Y), Vector2(260, 40), _ui_font(13), Color(1, 1, 1, 0.82), false)


## 创建真正的按钮控件，并绑定统一按压动效和按钮音效。
func _make_top_button(text: String, pos: Vector2, meta_name: String) -> Button:
	var btn := Button.new()
	btn.set_meta(meta_name, true)
	btn.position = pos
	btn.size = Vector2(TOP_BUTTON_W, TOP_BUTTON_H)
	btn.text = text
	btn.add_theme_font_size_override("font_size", _ui_font(14))
	btn.add_theme_color_override("font_color", Color("#443b32"))
	btn.add_theme_color_override("font_hover_color", Color("#443b32"))
	btn.add_theme_color_override("font_pressed_color", Color("#443b32"))
	btn.add_theme_color_override("font_focus_color", Color("#443b32"))
	var style := _style(Color("#ffe08a"), card_border, 5, 12)
	_apply_button_style_states(btn, style)
	_attach_button_press_feedback(btn)
	return btn


## 渲染游戏内设置弹窗，统一放置音频和导航动作。
func _render_settings_menu() -> void:
	var on_home := menu_active
	var panel_h := 340.0 if on_home else SETTINGS_PANEL_H
	var shade := ColorRect.new()
	shade.set_meta("settings_menu_overlay", true)
	shade.color = Color(0, 0, 0, 0.28)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.z_index = 210
	shade.gui_input.connect(_on_settings_overlay_gui_input)
	add_child(shade)

	var panel := Panel.new()
	panel.set_meta("settings_menu_panel", true)
	panel.size = Vector2(SETTINGS_PANEL_W, panel_h)
	panel.position = _center_in_safe_area(panel.size)
	panel.z_index = 211
	panel.add_theme_stylebox_override("panel", _style(Color("#fff7dc"), card_border, 6, 22))
	add_child(panel)

	var title_text := "设置" if on_home else "菜单"
	var title := _add_label(title_text, panel.position + Vector2(0, 34), Vector2(panel.size.x, 54), _ui_font(24), Color("#352f2b"), true)
	title.z_index = 212
	var close := _make_settings_close_button(panel)
	close.pressed.connect(_on_settings_close_pressed)
	add_child(close)

	var first_y := panel.position.y + 112.0
	var x := panel.position.x + (panel.size.x - SETTINGS_ACTION_W) * 0.5
	var music := _make_settings_button(
		"音乐：" + ("开" if music_enabled else "关"),
		Vector2(x, first_y),
		"music_toggle_button"
	)
	music.pressed.connect(_on_music_toggle_pressed)
	add_child(music)

	var sfx := _make_settings_button(
		"音效：" + ("开" if sfx_enabled else "关"),
		Vector2(x, first_y + (SETTINGS_ACTION_H + SETTINGS_ACTION_GAP)),
		"sfx_toggle_button"
	)
	sfx.pressed.connect(_on_sfx_toggle_pressed)
	add_child(sfx)

	if on_home:
		return

	var restart := _make_settings_button(
		"重新开始",
		Vector2(x, first_y + 2.0 * (SETTINGS_ACTION_H + SETTINGS_ACTION_GAP)),
		"restart_button"
	)
	restart.pressed.connect(_on_restart_pressed)
	add_child(restart)

	var home := _make_settings_button(
		"回到首页",
		Vector2(x, first_y + 3.0 * (SETTINGS_ACTION_H + SETTINGS_ACTION_GAP)),
		"home_button"
	)
	home.pressed.connect(_on_home_pressed)
	add_child(home)


## 创建设置弹窗里的标准按钮。
func _make_settings_button(text: String, pos: Vector2, meta_name: String) -> Button:
	var btn := Button.new()
	btn.set_meta(meta_name, true)
	btn.position = pos
	btn.size = Vector2(SETTINGS_ACTION_W, SETTINGS_ACTION_H)
	btn.text = text
	btn.z_index = 212
	btn.add_theme_font_size_override("font_size", _ui_font(14))
	btn.add_theme_color_override("font_color", Color("#443b32"))
	btn.add_theme_color_override("font_hover_color", Color("#443b32"))
	btn.add_theme_color_override("font_pressed_color", Color("#443b32"))
	btn.add_theme_color_override("font_focus_color", Color("#443b32"))
	var style := _style(Color("#ffe08a"), card_border, 5, 14)
	_apply_button_style_states(btn, style)
	_attach_button_press_feedback(btn)
	return btn


## 创建设置弹窗右上角关闭按钮。
func _make_settings_close_button(panel: Panel) -> Button:
	var btn := Button.new()
	btn.set_meta("settings_close_button", true)
	btn.size = Vector2(44, 44)
	var inset := 14.0
	btn.position = panel.position + Vector2(panel.size.x - btn.size.x - inset, inset)
	btn.text = ""
	btn.z_index = 213
	var style := _style(Color(1, 1, 1, 0), Color(0, 0, 0, 0), 0, 15)
	_apply_button_style_states(btn, style)
	_add_close_icon_line(btn, PI / 4.0)
	_add_close_icon_line(btn, -PI / 4.0)
	_attach_button_press_feedback(btn)
	return btn


## 给透明关闭按钮画一个几何 X，避免字体字形导致视觉边距不准。
func _add_close_icon_line(parent: Control, rotation: float) -> void:
	var line := ColorRect.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.color = Color("#544b4b", 0.84)
	line.size = Vector2(22, 3)
	line.position = (parent.size - line.size) * 0.5
	line.pivot_offset = line.size * 0.5
	line.rotation = rotation
	parent.add_child(line)


## 渲染 3 区类别槽位，不添加悬停反馈。
func _render_category_area() -> void:
	for i in range(MAX_CATEGORY_SLOTS):
		var pos := Vector2(_column_x(i), _layout_y(CATEGORY_Y))
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
			var category_style := _style(category_color, card_border, 6, 18)
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
			var slot_style := _style(category_empty_slot_color, Color(0, 0, 0, 0), 0, 18)
			_apply_button_style_states(slot, slot_style)
			_add_dashed_outline(slot, slot.size, Color("#ffe070", 0.86), 4.0, 14.0, 10.0, "category_slot_dash")
			add_child(slot)


## 渲染 4 区列牌和被覆盖牌露出的文字条。
func _render_board_area(next_card_positions: Dictionary) -> void:
	for col_idx in range(columns.size()):
		var x := _column_x(col_idx)
		var board_y := _layout_y(BOARD_Y)
		var column: Array = columns[col_idx]
		if column.is_empty():
			var empty := Button.new()
			empty.set_meta("board_empty_slot", true)
			empty.position = Vector2(x, board_y)
			empty.size = Vector2(CARD_W, CARD_H)
			empty.text = ""
			empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
			empty.add_theme_font_size_override("font_size", _ui_font(30))
			empty.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
			empty.add_theme_color_override("font_hover_color", Color(1, 1, 1, 0.45))
			empty.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 0.45))
			empty.add_theme_color_override("font_focus_color", Color(1, 1, 1, 0.45))
			var empty_style := _style(slot_color, Color(0, 0, 0, 0), 0, 18)
			_apply_button_style_states(empty, empty_style)
			_add_dashed_outline(empty, empty.size, Color(1, 1, 1, 0.42), 4.0, 14.0, 10.0, "board_slot_dash")
			add_child(empty)
			continue

		for card_idx in range(column.size()):
			var card: Dictionary = column[card_idx]
			var pos := Vector2(x, board_y + card_idx * STACK_STEP)
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


## 只刷新 1 区，用于吸收动画期间保持其它区域稳定。
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


## 只刷新 4 区，用于吸收动画期间同步翻牌/补位。
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


## 渲染胜利或失败弹窗。
func _render_overlay() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.35)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var panel := Panel.new()
	var show_extra_steps := _should_offer_extra_steps_ad()
	panel.size = Vector2(500, 360) if show_extra_steps else Vector2(500, 270)
	panel.position = _center_in_safe_area(panel.size)
	panel.add_theme_stylebox_override("panel", _style(Color("#fff7dc"), card_border, 6, 22))
	add_child(panel)

	_add_label(status_text, panel.position + Vector2(40, 54), Vector2(420, 64), _ui_font(24), Color("#352f2b"), true)
	var button_size := Vector2(190, 64)
	var button_gap := 24.0
	var buttons_x := panel.position.x + (panel.size.x - button_size.x * 2.0 - button_gap) * 0.5
	var buttons_y := panel.position.y + (246.0 if show_extra_steps else 156.0)
	var restart_style := _style(Color("#ffe08a"), card_border, 5, 14)

	if show_extra_steps:
		var extra_steps := _make_ad_action_button(
			"增加步数",
			Vector2(panel.position.x + 100.0, panel.position.y + 150.0),
			Vector2(300, 64),
			"extra_steps_ad_button",
			not _ad_is_showing()
		)
		extra_steps.pressed.connect(_on_extra_steps_ad_pressed)
		add_child(extra_steps)

	var restart := Button.new()
	restart.set_meta("restart_button", true)
	restart.size = button_size
	restart.position = Vector2(buttons_x, buttons_y)
	restart.text = "再来一局"
	restart.add_theme_font_size_override("font_size", _ui_font(20))
	restart.add_theme_color_override("font_color", Color("#544b4b"))
	restart.add_theme_color_override("font_hover_color", Color("#544b4b"))
	restart.add_theme_color_override("font_pressed_color", Color("#544b4b"))
	restart.add_theme_color_override("font_focus_color", Color("#544b4b"))
	_apply_button_style_states(restart, restart_style)
	restart.pressed.connect(_on_restart_pressed)
	_attach_button_press_feedback(restart)
	add_child(restart)

	var home := Button.new()
	home.set_meta("home_button", true)
	home.size = button_size
	home.position = Vector2(buttons_x + button_size.x + button_gap, buttons_y)
	home.text = "回到首页"
	home.add_theme_font_size_override("font_size", _ui_font(20))
	home.add_theme_color_override("font_color", Color("#544b4b"))
	home.add_theme_color_override("font_hover_color", Color("#544b4b"))
	home.add_theme_color_override("font_pressed_color", Color("#544b4b"))
	home.add_theme_color_override("font_focus_color", Color("#544b4b"))
	_apply_button_style_states(home, restart_style)
	home.pressed.connect(_on_home_pressed)
	_attach_button_press_feedback(home)
	add_child(home)


## 渲染独立开始菜单页面。
func _render_start_menu() -> void:
	var start := Button.new()
	start.set_meta("start_button", true)
	start.size = Vector2(280, 76)
	start.position = _center_in_safe_area(start.size)
	start.text = "开始游戏"
	start.add_theme_font_size_override("font_size", _ui_font(22))
	start.add_theme_color_override("font_color", Color("#443b32"))
	start.add_theme_color_override("font_hover_color", Color("#443b32"))
	start.add_theme_color_override("font_pressed_color", Color("#443b32"))
	start.add_theme_color_override("font_focus_color", Color("#443b32"))
	var start_style := _style(Color("#ffe08a"), card_border, 5, 16)
	_apply_button_style_states(start, start_style)
	start.z_index = 202
	start.pressed.connect(_on_start_pressed)
	_attach_button_press_feedback(start)
	add_child(start)

	if not tutorial_completed:
		return

	var settings := Button.new()
	settings.set_meta("home_settings_button", true)
	settings.size = Vector2(TOP_BUTTON_W, TOP_BUTTON_H)
	settings.position = _play_area_origin() + Vector2(TOP_CONTROL_X, TOP_CONTROL_Y)
	settings.text = "设置"
	settings.add_theme_font_size_override("font_size", _ui_font(14))
	settings.add_theme_color_override("font_color", Color("#443b32"))
	settings.add_theme_color_override("font_hover_color", Color("#443b32"))
	settings.add_theme_color_override("font_pressed_color", Color("#443b32"))
	settings.add_theme_color_override("font_focus_color", Color("#443b32"))
	_apply_button_style_states(settings, _style(Color("#ffe08a"), card_border, 5, 12))
	settings.z_index = 202
	settings.pressed.connect(_on_settings_pressed)
	_attach_button_press_feedback(settings)
	add_child(settings)

	var tutorial := Button.new()
	tutorial.set_meta("tutorial_button", true)
	tutorial.size = Vector2(TOP_BUTTON_W, TOP_BUTTON_H)
	tutorial.position = settings.position + Vector2(TOP_BUTTON_W + TOP_BUTTON_GAP, 0)
	tutorial.text = "教学"
	tutorial.add_theme_font_size_override("font_size", _ui_font(14))
	tutorial.add_theme_color_override("font_color", Color("#443b32"))
	tutorial.add_theme_color_override("font_hover_color", Color("#443b32"))
	tutorial.add_theme_color_override("font_pressed_color", Color("#443b32"))
	tutorial.add_theme_color_override("font_focus_color", Color("#443b32"))
	_apply_button_style_states(tutorial, _style(Color("#ffe08a"), card_border, 5, 12))
	tutorial.z_index = 202
	tutorial.pressed.connect(_on_tutorial_pressed)
	_attach_button_press_feedback(tutorial)
	add_child(tutorial)


## 渲染局内道具按钮。完成新手教学后才显示，库存为 0 时可显示广告入口。
func _render_prop_area() -> void:
	if prop_system == null or not prop_system.should_show():
		return
	var total_width := PROP_BUTTON_W * 2.0 + PROP_BUTTON_GAP
	var start_x := _play_area_origin().x + (GAME_W - total_width) * 0.5
	var y := _layout_y(PROP_BUTTON_Y)
	var hint := _make_prop_button(
		"hint",
		Vector2(start_x, y),
		"hint_prop_button",
		_can_press_hint_prop(),
		prop_system.count(PropSystemScript.PROP_HINT),
		_prop_needs_ad(PropSystemScript.PROP_HINT)
	)
	hint.pressed.connect(_on_hint_prop_pressed)
	add_child(hint)

	var undo := _make_prop_button(
		"undo",
		Vector2(start_x + PROP_BUTTON_W + PROP_BUTTON_GAP, y),
		"undo_prop_button",
		_can_press_undo_prop(),
		prop_system.count(PropSystemScript.PROP_UNDO),
		_prop_needs_ad(PropSystemScript.PROP_UNDO)
	)
	undo.pressed.connect(_on_undo_prop_pressed)
	add_child(undo)


## 创建局内道具按钮，并复用普通按钮的按压动效和音效。
func _make_prop_button(icon_name: String, pos: Vector2, meta_name: String, enabled: bool, count: int, ad_mode := false) -> Button:
	var btn := Button.new()
	btn.set_meta(meta_name, true)
	btn.position = pos
	btn.size = Vector2(PROP_BUTTON_W, PROP_BUTTON_H)
	btn.text = ""
	btn.disabled = not enabled
	btn.add_theme_color_override("font_color", Color("#443b32"))
	btn.add_theme_color_override("font_hover_color", Color("#443b32"))
	btn.add_theme_color_override("font_pressed_color", Color("#443b32"))
	btn.add_theme_color_override("font_focus_color", Color("#443b32"))
	btn.add_theme_color_override("font_disabled_color", Color("#766f67"))
	_apply_button_style_states(btn, _style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 18))
	btn.z_index = 120
	_add_prop_icon(btn, icon_name, enabled)
	if ad_mode:
		_add_prop_ad_badge(btn, enabled)
	else:
		_add_prop_badge(btn, count, enabled)
	_attach_button_press_feedback(btn)
	return btn


## 使用 GPT Image 生成并处理透明背景后的按钮资源。
func _add_prop_icon(parent: Button, icon_name: String, enabled: bool) -> void:
	var holder := TextureRect.new()
	holder.set_meta("prop_button_icon", true)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.texture = PropUndoTexture if icon_name == "undo" else PropHintTexture
	holder.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	holder.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	holder.size = parent.size
	holder.position = Vector2.ZERO
	holder.modulate = Color(1, 1, 1, 1) if enabled else Color(0.72, 0.70, 0.62, 1)
	parent.add_child(holder)


## 在道具按钮右上角绘制剩余数量角标，避免把数字拼进按钮主文案。
func _add_prop_badge(parent: Button, count: int, enabled: bool) -> void:
	var badge := Panel.new()
	badge.set_meta("prop_count_badge", true)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.size = Vector2(PROP_BADGE_SIZE, PROP_BADGE_SIZE)
	badge.position = Vector2(parent.size.x - PROP_BADGE_SIZE * 0.70, -PROP_BADGE_SIZE * 0.36)
	badge.z_index = parent.z_index + 1
	var fill := Color("#e94242") if enabled else PROP_DISABLED_COLOR
	badge.add_theme_stylebox_override("panel", _style(fill, Color.WHITE, 2, int(PROP_BADGE_SIZE * 0.5)))
	parent.add_child(badge)
	var label := _add_generated_label(badge, str(count), Vector2.ZERO, badge.size, _ui_font(13), Color.WHITE)
	label.position = Vector2(0, -1)
	label.add_theme_constant_override("line_spacing", 0)


## 道具次数为 0 但可以看广告使用时，角标显示广告播放标识。
func _add_prop_ad_badge(parent: Button, enabled: bool) -> void:
	var badge := Panel.new()
	badge.set_meta("prop_ad_badge", true)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.size = Vector2(PROP_BADGE_SIZE, PROP_BADGE_SIZE)
	badge.position = Vector2(parent.size.x - PROP_BADGE_SIZE * 0.70, -PROP_BADGE_SIZE * 0.36)
	badge.z_index = parent.z_index + 1
	var fill := Color("#4d9be8") if enabled else PROP_DISABLED_COLOR
	badge.add_theme_stylebox_override("panel", _style(fill, Color.WHITE, 2, int(PROP_BADGE_SIZE * 0.5)))
	parent.add_child(badge)
	_add_ad_play_texture_icon(badge, Color.WHITE, Vector2(8, 8), Vector2(20, 20))


## 创建带播放图标的广告动作按钮。
func _make_ad_action_button(text: String, pos: Vector2, button_size: Vector2, meta_name: String, enabled: bool) -> Button:
	var btn := Button.new()
	btn.set_meta(meta_name, true)
	btn.position = pos
	btn.size = button_size
	btn.text = text
	btn.disabled = not enabled
	btn.add_theme_font_size_override("font_size", _ui_font(18))
	btn.add_theme_color_override("font_color", Color("#544b4b"))
	btn.add_theme_color_override("font_hover_color", Color("#544b4b"))
	btn.add_theme_color_override("font_pressed_color", Color("#544b4b"))
	btn.add_theme_color_override("font_focus_color", Color("#544b4b"))
	btn.add_theme_color_override("font_disabled_color", Color("#7a746c"))
	_apply_button_style_states(btn, _style(Color("#ffe08a"), card_border, 5, 14))
	_add_ad_play_texture_icon(btn, Color("#544b4b"), Vector2(50, 20), Vector2(24, 24))
	_attach_button_press_feedback(btn)
	return btn


## 绘制简单播放三角形，避免引入额外广告图标资源。
func _add_ad_play_icon(parent: Control, color: Color, pos: Vector2, size_value: float) -> void:
	var icon := Polygon2D.new()
	icon.set_meta("ad_play_icon", true)
	icon.color = color
	icon.polygon = PackedVector2Array([
		pos,
		pos + Vector2(0.0, size_value),
		pos + Vector2(size_value * 0.86, size_value * 0.5),
	])
	icon.z_index = parent.z_index + 1
	parent.add_child(icon)


## 使用用户提供的 SVG 播放图标，确保广告入口图标统一。
func _add_ad_play_texture_icon(parent: Control, color: Color, pos: Vector2, icon_size: Vector2) -> void:
	var icon := TextureRect.new()
	icon.set_meta("ad_play_icon", true)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = AdPlayTexture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = pos
	icon.size = icon_size
	icon.modulate = color
	icon.z_index = parent.z_index + 1
	parent.add_child(icon)




## 提示按钮可用：有库存可直接用，或无库存但可通过广告补用。
func _can_press_hint_prop() -> bool:
	if prop_system == null or _ad_is_showing():
		return false
	return prop_system.can_use_hint() or _rewarded_action_is_available(AdServiceScript.PLACEMENT_PROP_HINT)


## 撤回按钮可用：有库存可直接用，或无库存但可通过广告补用。
func _can_press_undo_prop() -> bool:
	if prop_system == null or _ad_is_showing():
		return false
	return prop_system.can_use_undo() or _rewarded_action_is_available(AdServiceScript.PLACEMENT_PROP_UNDO)


## 道具角标是否应该显示广告标识。
func _prop_needs_ad(prop_name: String) -> bool:
	return prop_system != null and prop_system.count(prop_name) <= 0


## 渲染教学高亮和手势演示，不显示任何规则文案。
func _render_tutorial_guidance() -> void:
	if tutorial_overlay != null:
		tutorial_overlay.render(tutorial_controller.guidance())


## 道具提示复用教学遮罩/手势，但不接管输入。
func _render_prop_hint_guidance() -> void:
	if tutorial_overlay != null:
		tutorial_overlay.render(prop_system.hint_guidance())


## 创建卡牌按钮节点；卡牌本身不使用悬停态。
func _make_card_button(card: Dictionary, is_selected: bool, is_clickable: bool, override_text := "") -> Button:
	var btn := Button.new()
	btn.set_meta("card_id", card["id"])
	btn.disabled = game_over or not is_clickable
	_configure_card_button_visual(btn, card, is_selected, override_text)
	return btn


## 根据卡牌类型、朝向和文本配置卡牌视觉。
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
	_apply_button_style_states(btn, _style(fill, border, 6, 18))
	if card["type"] == "category" and card["face_up"] and display_text != "":
		var lines := display_text.split("\n")
		var progress := "0/" + str(categories.get(card["category"], []).size())
		if lines.size() > 1:
			progress = String(lines[1])
		btn.text = ""
		_add_category_card_labels(btn, String(lines[0]), progress, Color("#544b4b"))


## 将同一套样式应用到按钮所有状态，避免悬停造成视觉变化。
func _apply_button_style_states(btn: Button, style: StyleBoxFlat) -> void:
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("disabled", style)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


## 给空牌堆或空类别槽添加虚线边框。
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


## 给牌堆绘制“牌堆/剩余若干张”标签。
func _add_deck_count_labels(parent: Control) -> void:
	_add_generated_label(parent, "牌堆", Vector2(10, 52), Vector2(CARD_W - 20, 44), _ui_font(17), Color.WHITE)
	_add_generated_label(parent, "剩余" + str(deck.size()) + "张", Vector2(8, 100), Vector2(CARD_W - 16, 36), _ui_font(13), Color.WHITE)


## 绘制类别牌名称和固定字号的进度数字。
func _add_category_card_labels(parent: Control, category_name: String, progress: String, color: Color) -> void:
	_add_generated_label(parent, category_name, Vector2(10, 40), Vector2(CARD_W - 20, 62), _font_size_for_card_text(category_name, "category"), color)
	_add_generated_label(parent, progress, Vector2(10, 110), Vector2(CARD_W - 20, 38), _ui_font(16), color)


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


## 给普通按钮绑定按压缩放反馈。
func _attach_button_press_feedback(btn: Button) -> void:
	btn.pivot_offset = btn.size * 0.5
	btn.button_down.connect(_on_button_feedback_down.bind(btn))
	btn.button_up.connect(_on_button_feedback_up.bind(btn))


func _on_button_feedback_down(btn: Button) -> void:
	if not is_instance_valid(btn) or btn.disabled:
		return
	# 音效开关要等状态切换后再决定是否播放，避免“关”的那一下还响。
	if not btn.has_meta("sfx_toggle_button"):
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


## 播放 4 区新露出底牌的翻面动画。
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


## 4 区翻面动画结束后，将临时牌面合并回真实按钮。
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


## 处理普通卡牌节点的移动和出现动画。
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


## 创建从 2 区飞到 1 区的抽牌翻面动画节点。
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
	fly_card.position = Vector2(_column_x(3), _layout_y(DRAW_Y))
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


## 连续抽牌时重新计算飞行目标，让动画衔接更自然。
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


## 每帧推进抽牌飞行动画。
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


## 抽牌飞行动画结束后，确保真实 1 区牌堆包含这张牌。
func _finish_draw_card_animation(card_id: int) -> void:
	if draw_animation_cards.has(card_id):
		if not _draw_stack_has_card_id(card_id):
			draw_stack.append(draw_animation_cards[card_id])
	_discard_draw_animation(card_id)
	_render()


## 清理指定抽牌动画的临时节点和状态。
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


## 创建 1 区牌收拢并翻回 2 区的洗牌动画。
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
		"target": Vector2(_column_x(3), _layout_y(DRAW_Y)),
		"flipped": false,
	}


## 洗牌开始前清理仍在飞行的抽牌动画，避免牌面闪回。
func _clear_draw_animations_for_wash() -> void:
	for raw_card_id in draw_animation_nodes.keys():
		_discard_draw_animation(int(raw_card_id))
	draw_flights.clear()
	draw_animation_cards.clear()
	animating_draw_cards.clear()


## 每帧推进洗牌动画。
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


## 更新洗牌动画中主牌的缩放和翻面时机。
func _update_wash_keeper_visual(node: Control, t: float, eased: float) -> void:
	var base_scale: float = lerp(0.98, 1.0, eased)
	var depth_scale: float = 1.0 + 0.08 * sin(t * PI)
	var flip_scale: float = _flip_scale_for_progress(t, WASH_FLIP_FACE_TIME)
	node.scale = Vector2(base_scale * flip_scale * depth_scale, base_scale * depth_scale)
	node.rotation_degrees = 0.0


## 更新洗牌动画中被收拢牌的淡出和位移。
func _update_wash_under_card_visual(node: Control, t: float, eased: float) -> void:
	var under_scale: float = lerp(1.0, 0.96, eased)
	var flip_scale: float = _flip_scale_for_progress(t, WASH_FLIP_FACE_TIME)
	node.scale = Vector2(under_scale * flip_scale, under_scale)
	node.rotation_degrees = 0.0


## 根据动画进度计算模拟翻牌的水平缩放。
func _flip_scale_for_progress(t: float, flip_face_time: float) -> float:
	if t < flip_face_time:
		return max(0.08, cos((t / flip_face_time) * PI * 0.5))
	var open_t: float = (t - flip_face_time) / (1.0 - flip_face_time)
	return max(0.08, sin(open_t * PI * 0.5))


## 将洗牌动画中的牌切换为牌背。
func _set_wash_card_back(node: Control) -> void:
	if not is_instance_valid(node) or draw_stack.is_empty():
		return
	var back_card: Dictionary = draw_stack[draw_stack.size() - 1].duplicate()
	back_card["face_up"] = false
	_configure_card_button_visual(node as Button, back_card, false)
	(node as Button).disabled = true


## 洗牌动画完成后，才真正重置牌堆并打乱顺序。
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


## 返回卡牌正面应该显示的主文本。
func _card_text(card: Dictionary) -> String:
	if not card["face_up"]:
		return ""
	if card["type"] == "category":
		var total: int = categories.get(card["category"], []).size()
		return card["name"] + "\n0/" + str(total)
	return card["name"]


## 返回 4 区卡牌文本，类别牌会显示当前同组词语数量。
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


## 给被覆盖但已翻开的牌添加顶部露出文字条。
func _add_card_strip_label(parent: Control, text: String) -> void:
	var inset := 8.0
	var strip_height := STACK_STEP - inset - 6.0
	var backing := Panel.new()
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 露出条是子节点，会盖在卡牌边框上；必须缩进到黑色描边内部。
	backing.position = Vector2(inset, inset)
	backing.size = Vector2(CARD_W - inset * 2.0, strip_height)
	backing.add_theme_stylebox_override("panel", _style(Color(1, 1, 1, 0.72), Color(0, 0, 0, 0), 0, 5))
	parent.add_child(backing)

	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = Vector2(inset + 2.0, inset - 1.0)
	label.size = Vector2(CARD_W - (inset + 2.0) * 2.0, strip_height)
	label.text = text.replace("\n", " ")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", _font_size_for_strip_text(label.text))
	label.add_theme_color_override("font_color", Color("#544b4b"))
	parent.add_child(label)


## 根据文本长度计算牌面动态字号。
func _font_size_for_card_text(text: String, card_type: String) -> int:
	var longest_line := _longest_text_line_length(text)
	var base_size := 17
	if card_type == "category":
		if longest_line >= 6:
			base_size = 12
			return _ui_font(base_size)
		if longest_line >= 5:
			base_size = 13
			return _ui_font(base_size)
		if longest_line >= 4:
			base_size = 15
			return _ui_font(base_size)
		base_size = 16
		return _ui_font(base_size)
	if longest_line >= 6:
		base_size = 12
		return _ui_font(base_size)
	if longest_line >= 5:
		base_size = 13
		return _ui_font(base_size)
	if longest_line >= 4:
		base_size = 15
		return _ui_font(base_size)
	return _ui_font(base_size)


## 根据文本长度计算露出文字条字号。
func _font_size_for_strip_text(text: String) -> int:
	var longest_line := _longest_text_line_length(text)
	var base_size := 13
	if longest_line >= 6:
		base_size = 9
		return _ui_font(base_size)
	if longest_line >= 5:
		base_size = 10
		return _ui_font(base_size)
	if longest_line >= 4:
		base_size = 11
		return _ui_font(base_size)
	return _ui_font(base_size)


## 将旧 375 宽设计稿里的字号换算到 720 宽基准。
func _ui_font(base_size: int) -> int:
	return int(round(float(base_size) * UI_SCALE))


func _longest_text_line_length(text: String) -> int:
	var longest := 0
	for line in text.split("\n"):
		longest = max(longest, String(line).strip_edges().length())
	return longest


## 统计 4 区同组中已经翻开的词语牌数量。
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


## 返回牌堆为空时显示的洗牌/空牌堆文案。
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
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


## 根据当前视口宽度计算第几列的水平坐标。
func _column_x(col_idx: int) -> float:
	var total_width := BOARD_COLUMN_COUNT * CARD_W + (BOARD_COLUMN_COUNT - 1) * COL_GAP
	var start_x := _play_area_origin().x + (GAME_W - total_width) * 0.5
	return start_x + col_idx * (CARD_W + COL_GAP)


## 将设计稿里的纵坐标映射到安全区内的游戏区域。
func _layout_y(local_y: float) -> float:
	return _play_area_origin().y + local_y


## 返回安全区内居中的 720x1280 设计区域左上角。
func _play_area_origin() -> Vector2:
	return _play_area_origin_for_safe_rect(_safe_viewport_rect())


## 纯计算版本，便于测试横屏和刘海屏偏移。
func _play_area_origin_for_safe_rect(safe_rect: Rect2) -> Vector2:
	var x: float = safe_rect.position.x + max(0.0, (safe_rect.size.x - GAME_W) * 0.5)
	return Vector2(x, safe_rect.position.y)


## 将移动端 safe area 换算成当前拉伸后的逻辑坐标。
func _safe_viewport_rect() -> Rect2:
	var viewport_size := Vector2(GAME_W, GAME_H)
	if is_inside_tree():
		viewport_size = get_viewport_rect().size
	var full_rect := Rect2(Vector2.ZERO, viewport_size)
	if not is_inside_tree():
		return full_rect

	var raw_safe := DisplayServer.get_display_safe_area()
	var window_size_i := DisplayServer.window_get_size()
	if raw_safe.size.x <= 0 or raw_safe.size.y <= 0 or window_size_i.x <= 0 or window_size_i.y <= 0:
		return full_rect

	var window_size := Vector2(window_size_i)
	# 桌面端可能返回整块显示器安全区；和窗口尺寸明显不匹配时忽略，避免编辑器里产生错误偏移。
	if raw_safe.size.x > window_size.x * 1.1 or raw_safe.size.y > window_size.y * 1.1:
		return full_rect

	var scale := Vector2(viewport_size.x / window_size.x, viewport_size.y / window_size.y)
	var safe_rect := Rect2(Vector2(raw_safe.position) * scale, Vector2(raw_safe.size) * scale)
	return full_rect.intersection(safe_rect)


## 在 safe area 中居中放置弹窗和开始按钮。
func _center_in_safe_area(size: Vector2) -> Vector2:
	var safe_rect := _safe_viewport_rect()
	return safe_rect.position + (safe_rect.size - size) * 0.5


## 返回 1 区某张牌的显示位置。
func _draw_card_position(card_index: int) -> Vector2:
	return _draw_card_position_for_size(card_index, draw_stack.size())


## 保持 1 区顶牌在最右侧，较早的可见牌依次向左展开。
func _draw_card_position_for_size(card_index: int, stack_size: int) -> Vector2:
	var visible_count: int = min(3, stack_size)
	var first_visible_index: int = stack_size - visible_count
	var visible_offset: int = card_index - first_visible_index
	return Vector2(_column_x(2) - visible_offset * DRAW_STACK_SPREAD, _layout_y(DRAW_Y))


## 返回 3 区槽位的落点判定矩形。
func _category_slot_rect(slot_idx: int) -> Rect2:
	return Rect2(Vector2(_column_x(slot_idx), _layout_y(CATEGORY_Y)), Vector2(CARD_W, CARD_H))


## 将 4 区列的落点判定向下延伸，提升手机拖拽容错。
func _board_column_rect(col_idx: int) -> Rect2:
	var column_height := CARD_H
	if col_idx < columns.size() and not columns[col_idx].is_empty():
		column_height = CARD_H + (columns[col_idx].size() - 1) * STACK_STEP
	return Rect2(Vector2(_column_x(col_idx), _layout_y(BOARD_Y)), Vector2(CARD_W, column_height + BOARD_DROP_EXTRA_BOTTOM))


## 返回 2 区牌堆区域矩形。
func _deck_rect() -> Rect2:
	return Rect2(Vector2(_column_x(3), _layout_y(DRAW_Y)), Vector2(CARD_W, CARD_H))


func _on_deck_pressed() -> void:
	if menu_active:
		return
	_handle_deck_pressed()


## 处理牌堆的鼠标/触摸输入。
func _on_deck_gui_input(event: InputEvent) -> void:
	if menu_active or game_over or _ad_is_showing():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_deck_gui_pressed()
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		_handle_deck_gui_pressed()
		accept_event()


## 去重同一渲染帧里可能同时到达的鼠标/触摸事件。
func _handle_deck_gui_pressed() -> void:
	var current_frame := Engine.get_process_frames()
	if last_deck_gui_press_frame == current_frame:
		return
	last_deck_gui_press_frame = current_frame
	_handle_deck_pressed()


## 处理牌堆点击：抽牌、启动洗牌动画，或提示牌堆已空。
func _handle_deck_pressed() -> void:
	if game_over or deck_animation_busy or _ad_is_showing():
		return
	if _tutorial_active() and not tutorial_controller.allows_deck_press():
		return
	selected.clear()
	if deck.size() > 0:
		_record_undo_snapshot()
		_clear_prop_hint()
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
		_tutorial_action_succeeded({"action": "deck_draw"})
		return
	elif draw_stack.size() > 0:
		_record_undo_snapshot()
		_clear_prop_hint()
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


## 处理 1 区顶牌的拖拽输入。
func _on_draw_card_gui_input(event: InputEvent, card_index: int) -> void:
	if menu_active or game_over or _ad_is_showing():
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


## 处理 4 区可移动牌组的拖拽输入。
func _on_board_card_gui_input(event: InputEvent, col_idx: int, card_idx: int) -> void:
	if menu_active or game_over or _ad_is_showing():
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


## 在超过拖拽阈值前，先把按下事件记录为拖拽候选。
func _begin_drag_candidate(selection_data: Dictionary, local_pos: Vector2, global_pos: Vector2) -> void:
	if _tutorial_active() and not tutorial_controller.allows_drag_source(selection_data):
		return
	drag_candidate = selection_data
	drag_candidate["pressed_local"] = local_pos
	drag_candidate["pressed_global"] = global_pos
	drag_candidate["dragging"] = false
	drag_offset = local_pos + Vector2(0, float(selection_data.get("drag_offset_y", 0.0)))


## 启动并移动跟随手指的真实牌组预览。
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


## 松手时尝试执行合法移动，否则播放取消动画。
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


## 根据松手位置，把选中牌组路由到 3 区或 4 区。
func _drop_selected_at(global_pos: Vector2) -> void:
	var local_pos := get_global_transform().affine_inverse() * global_pos
	for i in range(MAX_CATEGORY_SLOTS):
		if _category_slot_rect(i).has_point(local_pos):
			if _category_slot_occupied(i):
				var category: String = active_order[i]
				var target := {"kind": "active_category", "category": category, "slot": i}
				if _tutorial_active() and not tutorial_controller.allows_drop_target(selected, target):
					_cancel_drag_drop()
					return
				var snapshot_pushed := _record_undo_snapshot()
				if _move_selected_to_active_category(category):
					_clear_prop_hint()
					_pending_tutorial_success({"action": "move_to_active_category"})
					selected["absorb_target_position"] = Vector2(_column_x(i), _layout_y(CATEGORY_Y))
					selected["absorb_target_slot"] = i
					_after_successful_move()
				else:
					_discard_undo_snapshot(snapshot_pushed)
					_cancel_drag_drop()
			else:
				var target := {"kind": "category_empty", "slot": i}
				if _tutorial_active() and not tutorial_controller.allows_drop_target(selected, target):
					_cancel_drag_drop()
					return
				var snapshot_pushed := _record_undo_snapshot()
				if _move_selected_to_empty_category(i):
					_clear_prop_hint()
					_pending_tutorial_success({"action": "move_to_empty_category"})
					_after_successful_move()
				else:
					_discard_undo_snapshot(snapshot_pushed)
					_cancel_drag_drop()
			return
	for col_idx in range(BOARD_COLUMN_COUNT):
		if _board_column_rect(col_idx).has_point(local_pos):
			var target := {"kind": "board_column", "col": col_idx}
			if _tutorial_active() and not tutorial_controller.allows_drop_target(selected, target):
				_cancel_drag_drop()
				return
			var snapshot_pushed := _record_undo_snapshot()
			if _move_selected_to_column(col_idx):
				_clear_prop_hint()
				_pending_tutorial_success({"action": "move_to_column"})
				_after_successful_move()
			else:
				_discard_undo_snapshot(snapshot_pushed)
				_cancel_drag_drop()
			return
	_cancel_drag_drop()


## 取消当前拖拽放置。
func _cancel_drag_drop() -> void:
	status_text = "不能放到这里"
	if drag_preview != null and is_instance_valid(drag_preview):
		_animate_drag_cancel()
	else:
		selected.clear()
		_render()


## 非法放置时，将拖拽牌组动画退回来源位置。
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


## 拖拽取消动画结束后恢复真实牌面。
func _finish_drag_cancel_animation() -> void:
	if is_instance_valid(returning_drag_preview):
		returning_drag_preview.queue_free()
	returning_drag_preview = null
	selected.clear()
	_render()


## 构造拖拽过程中跟随指针移动的可见牌组。
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


## 返回拖拽牌组中某张牌应该显示的文本。
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


## 拖拽开始后隐藏来源处真实卡牌，避免和预览重叠。
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


## 拖拽开始时给牌组一个轻微确认动效。
func _pulse_drag_preview() -> void:
	if drag_preview == null:
		return
	drag_preview.scale = Vector2(1.03, 1.03)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(drag_preview, "scale", Vector2.ONE, 0.12)


## 启动幕布转场，用来遮住新牌局生成过程。
func _start_new_round(message: String) -> void:
	if round_transition_active:
		return
	pending_round_message = message
	_play_round_close_transition()


## 重置所有玩法状态，并构建下一局经过求解器验证的牌局。
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
	extra_steps_ad_used = false
	pending_rewarded_placement = ""
	game_over = false
	menu_active = false
	status_text = message
	if prop_system != null:
		prop_system.reset_round()
	_init_level()
	_render()


## 修改牌局状态前，先合上上下幕布。
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


## 幕布合上后，在遮挡下切换到新牌局。
func _finish_round_close_transition(overlay: Control) -> void:
	_kill_round_transition_tween()
	if not is_instance_valid(overlay):
		round_transition_active = false
		return
	_setup_new_round(pending_round_message)
	_start_round_transition_hold(overlay)


## 幕布完全合上后短暂停顿，让切换不显得突兀。
func _start_round_transition_hold(overlay: Control) -> void:
	if not is_instance_valid(overlay):
		round_transition_active = false
		return
	_kill_round_transition_tween()
	var tween := create_tween()
	round_transition_tween = tween
	tween.tween_interval(ROUND_TRANSITION_HOLD_TIME)
	tween.tween_callback(_play_round_open_transition.bind(overlay))


## 给幕布边缘添加细微明暗线，避免纯色块显得生硬。
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


## 新局面已经在幕布下渲染完成后，再打开幕布。
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


## 幕布打开后清理转场节点并恢复输入。
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


## 清理当前回合转场节点和补间动画。
func _clear_round_transition() -> void:
	_kill_round_transition_tween()
	if is_instance_valid(round_transition_overlay):
		round_transition_overlay.queue_free()
	round_transition_overlay = null
	round_transition_active = false
	pending_round_message = ""


## 安全停止当前幕布补间动画。
func _kill_round_transition_tween() -> void:
	if is_instance_valid(round_transition_tween):
		round_transition_tween.kill()
	round_transition_tween = null


## 重新开始按钮回调。
func _on_restart_pressed() -> void:
	settings_menu_open = false
	if _tutorial_active():
		_start_tutorial()
		return
	_start_new_round("点击牌堆开始")


## 首页按钮回调。
func _on_home_pressed() -> void:
	_clear_transient_interaction_state()
	_clear_prop_hint()
	if tutorial_controller != null:
		tutorial_controller.active = false
	menu_active = true
	settings_menu_open = false
	game_over = false
	pending_rewarded_placement = ""
	selected.clear()
	_render()


## 开始游戏按钮回调。
func _on_start_pressed() -> void:
	settings_menu_open = false
	if tutorial_controller != null:
		tutorial_controller.active = false
	if not tutorial_completed:
		_start_tutorial()
		return
	_start_new_round("开始游戏")


## 首页教学按钮回调。
func _on_tutorial_pressed() -> void:
	_start_tutorial()


## 点击提示道具：消耗一次并显示下一步可操作的教程式引导。
func _on_hint_prop_pressed() -> void:
	if prop_system == null:
		return
	if prop_system.count(PropSystemScript.PROP_HINT) > 0:
		prop_system.use_hint()
		return
	_request_rewarded_ad(AdServiceScript.PLACEMENT_PROP_HINT)


## 点击撤回道具：恢复到上一个正式动作之前。
func _on_undo_prop_pressed() -> void:
	if prop_system == null:
		return
	if prop_system.count(PropSystemScript.PROP_UNDO) > 0:
		prop_system.use_undo()
		return
	_request_rewarded_ad(AdServiceScript.PLACEMENT_PROP_UNDO)


## 进入固定教学关。
func _start_tutorial() -> void:
	_clear_transient_interaction_state()
	_clear_prop_hint()
	settings_menu_open = false
	game_over = false
	menu_active = false
	if tutorial_controller == null:
		_init_tutorial()
	tutorial_controller.start()
	_render()


## 打开游戏内设置菜单。
func _on_settings_pressed() -> void:
	if game_over or round_transition_active or _ad_is_showing():
		return
	settings_menu_open = true
	_render()


## 关闭游戏内设置菜单。
func _on_settings_close_pressed() -> void:
	settings_menu_open = false
	_render()


## 点击设置弹窗外部遮罩时继续游戏。
func _on_settings_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_settings_close_pressed()


## 切换背景音乐开关。
func _on_music_toggle_pressed() -> void:
	music_enabled = not music_enabled
	_sync_audio_enabled_state()
	_save_user_settings()
	_render()


## 切换所有短音效开关。
func _on_sfx_toggle_pressed() -> void:
	sfx_enabled = not sfx_enabled
	_sync_audio_enabled_state()
	_save_user_settings()
	if sfx_enabled:
		_play_button_click_sfx()
	_render()


## 非正式包广告后门的异步完成入口，由 DebugAdProvider 下一帧调用。
func _debug_complete_rewarded_ad(placement: String) -> void:
	if ad_service != null:
		ad_service.complete_debug_rewarded_ad(placement)


## 请求激励广告，并在等待 SDK/Provider 回调时暂停局内输入。
func _request_rewarded_ad(placement: String) -> bool:
	if ad_service == null or pending_rewarded_placement != "":
		return false
	if not _rewarded_action_is_available(placement):
		status_text = "广告暂不可用"
		_render()
		return false
	if not ad_service.can_show_rewarded(placement):
		status_text = "广告暂不可用"
		_render()
		return false
	pending_rewarded_placement = placement
	_render()
	if ad_service.show_rewarded(placement):
		return true
	pending_rewarded_placement = ""
	status_text = "广告暂不可用"
	_render()
	return false


## 指定广告位当前是否有可奖励的业务动作；不判断真实广告是否已加载。
func _rewarded_action_is_available(placement: String) -> bool:
	if placement == AdServiceScript.PLACEMENT_PROP_HINT:
		return prop_system != null and prop_system.can_request_hint_ad()
	if placement == AdServiceScript.PLACEMENT_PROP_UNDO:
		return prop_system != null and prop_system.can_request_undo_ad()
	if placement == AdServiceScript.PLACEMENT_EXTRA_STEPS:
		return _should_offer_extra_steps_ad()
	return false


## 激励广告完整看完后，根据广告位发放奖励。
func _on_rewarded_ad_completed(placement: String) -> void:
	if pending_rewarded_placement != placement:
		return
	pending_rewarded_placement = ""
	if placement == AdServiceScript.PLACEMENT_PROP_HINT:
		prop_system.add_count(PropSystemScript.PROP_HINT, 1)
		prop_system.use_hint()
	elif placement == AdServiceScript.PLACEMENT_PROP_UNDO:
		prop_system.add_count(PropSystemScript.PROP_UNDO, 1)
		prop_system.use_undo()
	elif placement == AdServiceScript.PLACEMENT_EXTRA_STEPS:
		extra_steps_ad_used = true
		steps_left += EXTRA_STEPS_AD_REWARD
		game_over = false
		status_text = "获得步数"
		_render()
	_save_user_settings()


## 激励广告没有完成时恢复当前流程，不发放奖励。
func _on_rewarded_ad_failed(placement: String, _reason: String) -> void:
	if pending_rewarded_placement != placement:
		return
	pending_rewarded_placement = ""
	status_text = "步数用完" if placement == AdServiceScript.PLACEMENT_EXTRA_STEPS else "广告暂不可用"
	_render()


## 从本地用户配置读取上次保存的音频开关。
func _load_user_settings() -> void:
	var config := ConfigFile.new()
	if config.load(user_settings_path) != OK:
		return
	music_enabled = bool(config.get_value(USER_SETTINGS_SECTION, "music_enabled", music_enabled))
	sfx_enabled = bool(config.get_value(USER_SETTINGS_SECTION, "sfx_enabled", sfx_enabled))
	tutorial_completed = bool(config.get_value(TutorialControllerScript.SETTINGS_SECTION, TutorialControllerScript.SETTINGS_COMPLETED_KEY, tutorial_completed))
	if prop_system != null:
		prop_system.set_count(PropSystemScript.PROP_HINT, int(config.get_value(PROP_SETTINGS_SECTION, PropSystemScript.PROP_HINT, prop_system.count(PropSystemScript.PROP_HINT))))
		prop_system.set_count(PropSystemScript.PROP_UNDO, int(config.get_value(PROP_SETTINGS_SECTION, PropSystemScript.PROP_UNDO, prop_system.count(PropSystemScript.PROP_UNDO))))


## 保存当前音频开关，下次启动自动恢复。
func _save_user_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(USER_SETTINGS_SECTION, "music_enabled", music_enabled)
	config.set_value(USER_SETTINGS_SECTION, "sfx_enabled", sfx_enabled)
	config.set_value(TutorialControllerScript.SETTINGS_SECTION, TutorialControllerScript.SETTINGS_COMPLETED_KEY, tutorial_completed)
	if prop_system != null:
		config.set_value(PROP_SETTINGS_SECTION, PropSystemScript.PROP_HINT, prop_system.count(PropSystemScript.PROP_HINT))
		config.set_value(PROP_SETTINGS_SECTION, PropSystemScript.PROP_UNDO, prop_system.count(PropSystemScript.PROP_UNDO))
	config.save(user_settings_path)


## 根据当前开关状态同步实际音频播放器。
func _sync_audio_enabled_state() -> void:
	if is_instance_valid(music_player):
		if music_enabled:
			if music_player.is_inside_tree():
				if not music_player.playing:
					music_player.play()
				music_player.stream_paused = false
		else:
			if music_player.is_inside_tree():
				# Web 端被浏览器拦截的 play() 可能在首次点击后恢复；关闭时直接 stop。
				music_player.stop()
				music_player.stream_paused = false
	for player in sfx_players:
		if is_instance_valid(player) and not sfx_enabled:
			player.stop()
	for player in button_sfx_players:
		if is_instance_valid(player) and not sfx_enabled:
			player.stop()


## 清理动画、拖拽预览和其他临时交互状态。
func _clear_transient_interaction_state(clear_transition := true) -> void:
	if clear_transition:
		_clear_round_transition()
	drag_candidate.clear()
	selected.clear()
	pending_tutorial_action.clear()
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
	pending_rewarded_placement = ""


## 在正式动作改变局面之前记录撤回快照。
func _record_undo_snapshot() -> bool:
	if prop_system == null:
		return false
	var before_size: int = prop_system.undo_stack.size()
	prop_system.push_undo_snapshot()
	return prop_system.undo_stack.size() > before_size


## 动作最终失败时，清理刚刚为它准备的撤回快照。
func _discard_undo_snapshot(snapshot_pushed: bool) -> void:
	if snapshot_pushed and prop_system != null:
		prop_system.discard_latest_undo_snapshot()


## 成功动作、跳转流程或重开前隐藏当前提示。
func _clear_prop_hint() -> void:
	if prop_system != null:
		prop_system.clear_hint()


## 只有 1 区最上方的牌能成为可移动来源。
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


## 返回 4 区某列底部可移动的同类别整组牌。
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
		"return_position": Vector2(_column_x(col_idx), _layout_y(BOARD_Y) + group_start * STACK_STEP),
		"drag_offset_y": float(card_idx - group_start) * STACK_STEP,
	}


## 如果目标列允许，则把选中牌组移入 4 区。
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
		previous_card_positions[card["id"]] = Vector2(_column_x(col_idx), _layout_y(BOARD_Y) + (target.size() - 1) * STACK_STEP)
		suppress_next_move_animations[card["id"]] = true
	status_text = "移动到 4 区"
	return true


## 将选中的词语牌吸收到 3 区已有类别中。
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


## 将包含类别牌的牌组放入 3 区空槽。
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


## 从来源移除选中牌，并翻开新露出的 4 区牌。
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


## 1 区顶牌移走后，准备已翻开牌向左补位的动画。
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


## 翻开新露出的 4 区底牌，并标记它需要播放翻面动画。
func _reveal_bottom_card(col_idx: int) -> void:
	var column: Array = columns[col_idx]
	if column.is_empty():
		return
	var bottom: Dictionary = column[column.size() - 1]
	if not bottom["face_up"]:
		bottom["face_up"] = true
		if is_inside_tree():
			revealing_board_cards[bottom["id"]] = true


## 吸收匹配词语牌，并返回类别是否已经集齐。
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


## 消耗步数前，选择本次移动后应该播放的动画路径。
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


## 将词语牌动画吸收到 3 区类别牌中心。
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


## 词语吸收飞行动画结束，接着播放类别牌缩放反馈。
func _finish_category_absorb_animation() -> void:
	if is_instance_valid(absorbing_drag_preview):
		absorbing_drag_preview.queue_free()
	absorbing_drag_preview = null
	if _pulse_absorb_category_slot(pending_absorb_slot, _finish_category_absorb_pulse):
		return
	_finish_category_absorb_pulse()


## 吸收确认反馈结束后才扣除本次移动步数。
func _finish_category_absorb_pulse() -> void:
	pending_absorb_slot = -1
	selected.clear()
	_consume_step(status_text)


## 类别刚集齐时，先播放确认反馈，再从 3 区移除。
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


## 类别完成的第一段确认反馈结束后，播放消失动画。
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


## 类别完成消失动画结束后，真正移除 3 区类别。
func _finish_completed_category_disappear() -> void:
	if completing_category_name != "":
		active_categories.erase(completing_category_name)
		_clear_category_slot(completing_category_name)
	completing_category_slot = -1
	completing_category_name = ""
	selected.clear()
	_consume_step(status_text)


## 给接收词语的类别牌一个轻微的确认缩放反馈。
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


## 查找指定 3 区槽位的类别牌节点。
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


## 标记选中牌下次重绘不播放普通位移动画。
func _suppress_selected_move_animations() -> void:
	for card in selected.get("cards", []):
		suppress_next_move_animations[card["id"]] = true


## 消耗一步、检查终局状态，然后重绘。
func _consume_step(message: String) -> void:
	steps_left -= 1
	status_text = message
	_check_end_state()
	_flush_pending_tutorial_success()
	_render()


## 应用胜利、步数耗尽和无法移动三种终局条件。
func _check_end_state() -> void:
	if _tutorial_active():
		return
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


## 当前是否处于广告播放/等待回调状态。
func _ad_is_showing() -> bool:
	return pending_rewarded_placement != ""


## 步数用完弹窗是否显示广告加步数入口。
func _should_offer_extra_steps_ad() -> bool:
	return game_over \
		and status_text == "步数用完" \
		and not extra_steps_ad_used


## 步数用完后请求激励广告；成功回调后本局只奖励一次 +20 步。
func _on_extra_steps_ad_pressed() -> void:
	_request_rewarded_ad(AdServiceScript.PLACEMENT_EXTRA_STEPS)


## 暂存一次教学动作成功，等待正式动画和扣步流程完成后再推进步骤。
func _pending_tutorial_success(action: Dictionary) -> void:
	if _tutorial_active():
		pending_tutorial_action = action.duplicate()


## 立即通知教学控制器动作成功，用于抽牌这种没有走 _consume_step 的动作。
func _tutorial_action_succeeded(action: Dictionary) -> void:
	if not _tutorial_active():
		return
	tutorial_controller.notify_action_succeeded(action)
	if _tutorial_active():
		_render()


## 在正式移动扣步后推进教学，避免教学状态切换抢在动画/吸收流程前面。
func _flush_pending_tutorial_success() -> void:
	if pending_tutorial_action.is_empty():
		return
	var action := pending_tutorial_action.duplicate()
	pending_tutorial_action.clear()
	_tutorial_action_succeeded(action)


## 判断当前是否已经清空所有牌和类别。
func _is_win() -> bool:
	if not deck.is_empty() or not draw_stack.is_empty() or not active_categories.is_empty():
		return false
	for column in columns:
		if not column.is_empty():
			return false
	return true


## 判断当前静态局面是否存在任意合法移动。
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


## 判断玩家是否还能抽牌、洗牌、等待动画，或执行合法移动。
func _has_any_available_step() -> bool:
	if _has_pending_card_motion():
		return true
	if not deck.is_empty():
		return true
	if not draw_stack.is_empty():
		return true
	return _has_any_legal_move()


## 判断是否还有会影响终局判定的动画未结束。
func _has_pending_card_motion() -> bool:
	return not draw_flights.is_empty() \
		or not draw_animation_cards.is_empty() \
		or not wash_flight.is_empty() \
		or not wash_animation_nodes.is_empty() \
		or absorbing_drag_preview != null \
		or returning_drag_preview != null \
		or drag_preview != null \
		or completing_category_name != ""


## 判断 1 区顶牌是否有合法去处。
func _top_draw_has_move() -> bool:
	if draw_stack.is_empty():
		return false
	return _group_has_move([draw_stack[draw_stack.size() - 1]], -1)


## 判断某个牌组是否能移动到 3 区或其它 4 区列。
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


## 判断 3 区指定槽位是否已有类别。
func _category_slot_occupied(slot_idx: int) -> bool:
	return slot_idx < active_order.size() and active_order[slot_idx] != "" and active_categories.has(active_order[slot_idx])


## 将类别写入 3 区指定槽位。
func _set_category_slot(slot_idx: int, category: String) -> void:
	while active_order.size() <= slot_idx:
		active_order.append("")
	active_order[slot_idx] = category


## 清空 3 区中指定类别所在槽位。
func _clear_category_slot(category: String) -> void:
	for i in range(active_order.size()):
		if active_order[i] == category:
			active_order[i] = ""
			return


## 判断 3 区是否还有空槽。
func _has_empty_category_slot() -> bool:
	if active_order.size() < MAX_CATEGORY_SLOTS:
		return true
	for i in range(MAX_CATEGORY_SLOTS):
		if active_order[i] == "" or not active_categories.has(active_order[i]):
			return true
	return false


## 返回某列底部可移动的同类别牌组。
func _bottom_group(column: Array) -> Array:
	if column.is_empty():
		return []
	var start := _group_start_index(column)
	if start < 0:
		return []
	return column.slice(start)


## 返回 4 区列中可移动底部牌组的起点下标。
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


## 返回一组牌所属类别。
func _group_category(cards: Array) -> String:
	if cards.is_empty():
		return ""
	return cards[0]["category"]


## 判断一组牌里是否包含类别牌。
func _group_has_category(cards: Array) -> bool:
	for card in cards:
		if card["type"] == "category":
			return true
	return false


## 返回牌组的调试标签。
func _group_label(cards: Array) -> String:
	var names: Array[String] = []
	for card in cards:
		names.append(card["name"])
	return " / ".join(names)


## 判断当前选中牌组是否包含指定卡牌编号。
func _selected_has_card(card_id: int) -> bool:
	if selected.is_empty():
		return false
	for card in selected.get("cards", []):
		if card["id"] == card_id:
			return true
	return false
