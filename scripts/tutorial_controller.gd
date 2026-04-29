## 新手教学控制器。
##
## 教学逻辑尽量独立于主场景：这里负责固定教学关、步骤推进、动作白名单
## 和本地完成状态；主场景只负责实际移动、动画、渲染高亮和手势。
class_name TutorialController
extends RefCounted

const SETTINGS_SECTION := "tutorial"
const SETTINGS_COMPLETED_KEY := "completed"

var game: Node
var active := false
var step_index := 0
var steps: Array[Dictionary] = []


func _init(game_scene: Node) -> void:
	game = game_scene
	_build_steps()


## 返回用户是否已经完成过教学。
static func load_completed(settings_path: String) -> bool:
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		return false
	return bool(config.get_value(SETTINGS_SECTION, SETTINGS_COMPLETED_KEY, false))


## 写入教学完成状态。
static func save_completed(settings_path: String, completed: bool) -> void:
	var config := ConfigFile.new()
	config.load(settings_path)
	config.set_value(SETTINGS_SECTION, SETTINGS_COMPLETED_KEY, completed)
	config.save(settings_path)


## 开始固定教学关。
func start() -> void:
	active = true
	step_index = 0
	_setup_intro_deal()


## 结束教学并保存完成状态。
func finish() -> void:
	active = false
	save_completed(game.user_settings_path, true)
	game.tutorial_completed = true
	game.menu_active = false
	game.game_over = true
	game.status_text = "过关成功"


## 返回教学是否正在接管当前局。
func is_active() -> bool:
	return active


## 返回当前教学步骤；越界或未激活时返回空字典。
func current_step() -> Dictionary:
	if not active or step_index < 0 or step_index >= steps.size():
		return {}
	return steps[step_index]


## 当前步骤是否允许点击牌堆。
func allows_deck_press() -> bool:
	var step := current_step()
	return step.get("action", "") == "deck_draw"


## 当前步骤是否允许从这个来源开始拖拽。
func allows_drag_source(selection: Dictionary) -> bool:
	var step := current_step()
	if step.is_empty():
		return false
	var expected: Dictionary = step.get("source", {})
	if expected.is_empty():
		return false
	return _selection_matches_ref(selection, expected)


## 当前步骤是否允许把选中牌组放到目标位置。
func allows_drop_target(selection: Dictionary, target: Dictionary) -> bool:
	var step := current_step()
	if step.is_empty():
		return false
	if not allows_drag_source(selection):
		return false
	var expected: Dictionary = step.get("target", {})
	return _target_matches_ref(target, expected)


## 通知教学动作成功。
func notify_action_succeeded(action: Dictionary) -> void:
	if not active:
		return
	var step := current_step()
	if step.is_empty() or String(action.get("action", "")) != String(step.get("action", "")):
		return

	step_index += 1
	if step_index >= steps.size():
		finish()


## 当前步骤的高亮和手势引用，由主场景转换成实际矩形。
func guidance() -> Dictionary:
	var step := current_step()
	if step.is_empty():
		return {}
	return {
		"gesture": step.get("gesture", "drag"),
		"source": step.get("source", {}),
		"target": step.get("target", {}),
	}


## 组装固定教学流程。步骤中的 source/target 是主场景可解析的抽象引用。
func _build_steps() -> void:
	steps = [
		{
			"action": "deck_draw",
			"gesture": "tap",
			"source": {"kind": "deck"},
			"target": {"kind": "draw_top"},
		},
		{
			"action": "move_to_column",
			"gesture": "drag",
			"source": {"kind": "draw_top", "card_name": "苹果"},
			"target": {"kind": "board_column", "col": 0},
		},
		{
			"action": "move_to_column",
			"gesture": "drag",
			"source": {"kind": "board_group", "col": 2, "card_name": "水果"},
			"target": {"kind": "board_column", "col": 0},
		},
		{
			"action": "move_to_empty_category",
			"gesture": "drag",
			"source": {"kind": "board_group", "col": 0, "card_name": "水果"},
			"target": {"kind": "category_empty", "slot": 0},
		},
		{
			"action": "move_to_active_category",
			"gesture": "drag",
			"source": {"kind": "board_group", "col": 3, "card_name": "葡萄"},
			"target": {"kind": "active_category", "category": "水果"},
		},
		{
			"action": "move_to_empty_category",
			"gesture": "drag",
			"source": {"kind": "board_group", "col": 3, "card_name": "文具"},
			"target": {"kind": "category_empty", "slot": 0},
		},
		{
			"action": "move_to_active_category",
			"gesture": "drag",
			"source": {"kind": "board_group", "col": 1, "card_name": "橡皮"},
			"target": {"kind": "active_category", "category": "文具"},
		},
	]


## 设置完整教学牌局：一局内完成翻牌、合并、封口、直接类别和吸收。
func _setup_intro_deal() -> void:
	_reset_game_state()
	game.categories = {
		"水果": ["苹果", "香蕉", "葡萄", "橙子"],
		"文具": ["橡皮", "尺子"],
	}
	_rebuild_word_index()
	game.deck = [game._word("苹果", false)]
	game.draw_stack = []
	game.columns = [
		[game._word("香蕉", true)],
		[game._word("橡皮", true), game._word("尺子", true)],
		[game._category("水果", true)],
		[game._category("文具", false), game._word("葡萄", true), game._word("橙子", true)],
	]
	game.steps_left = 20
	game.status_text = "tutorial"


## 清空正式局的临时状态，让固定教学关不受上一局动画和选择态影响。
func _reset_game_state() -> void:
	game._clear_transient_interaction_state()
	game.deck.clear()
	game.draw_stack.clear()
	game.columns.clear()
	game.active_categories.clear()
	game.active_order.clear()
	game.selected.clear()
	game.game_over = false
	game.settings_menu_open = false
	game.menu_active = false
	game.previous_card_positions.clear()
	game.pending_spawn_positions.clear()


## 根据教学固定类别重建词语到类别的索引。
func _rebuild_word_index() -> void:
	game.word_to_category.clear()
	for category in game.categories.keys():
		for word in game.categories[category]:
			game.word_to_category[word] = category


## 判断玩家拿起的牌组是否正是当前步骤允许的来源。
func _selection_matches_ref(selection: Dictionary, ref: Dictionary) -> bool:
	if selection.is_empty():
		return false
	match String(ref.get("kind", "")):
		"draw_top":
			return selection.get("source", "") == "draw" \
				and _selection_has_card(selection, String(ref.get("card_name", "")))
		"board_group":
			return selection.get("source", "") == "board" \
				and int(selection.get("col", -1)) == int(ref.get("col", -2)) \
				and _selection_has_card(selection, String(ref.get("card_name", "")))
		_:
			return false


## 判断玩家松手的位置是否正是当前步骤允许的目标。
func _target_matches_ref(target: Dictionary, ref: Dictionary) -> bool:
	match String(ref.get("kind", "")):
		"board_column":
			return target.get("kind", "") == "board_column" \
				and int(target.get("col", -1)) == int(ref.get("col", -2))
		"category_empty":
			return target.get("kind", "") == "category_empty" \
				and int(target.get("slot", -1)) == int(ref.get("slot", -2))
		"active_category":
			return target.get("kind", "") == "active_category" \
				and String(target.get("category", "")) == String(ref.get("category", ""))
		_:
			return false


## 允许用牌名约束整组选牌，保证玩家必须按教学指定牌组操作。
func _selection_has_card(selection: Dictionary, card_name: String) -> bool:
	if card_name == "":
		return true
	for card in selection.get("cards", []):
		if String(card.get("name", "")) == card_name:
			return true
	return false
