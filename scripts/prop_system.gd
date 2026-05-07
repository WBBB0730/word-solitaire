## 局内道具系统。
##
## 第一版只使用每局固定数量。这里刻意把数量、撤回快照和提示搜索集中管理，
## 后续改成永久库存、广告奖励或付费消耗时，主场景只需要继续调用同一组入口。
class_name PropSystem
extends RefCounted

const PROP_HINT := "hint"
const PROP_UNDO := "undo"
const DEFAULT_COUNTS := {
	PROP_HINT: 3,
	PROP_UNDO: 3,
}
const MAX_UNDO_HISTORY := 32

var game: Node
var counts := {}
var undo_stack: Array[Dictionary] = []
var active_hint := {}


func _init(game_scene: Node) -> void:
	game = game_scene
	reset_round()


## 开始新局时重置本局固定道具数量和撤回历史。
func reset_round() -> void:
	counts = DEFAULT_COUNTS.duplicate()
	undo_stack.clear()
	active_hint.clear()


## 当前是否应该显示局内道具入口。
func should_show() -> bool:
	return _round_props_enabled() \
		and not game._has_pending_card_motion()


## 返回指定道具剩余数量。
func count(prop_name: String) -> int:
	return int(counts.get(prop_name, 0))


## 是否可以点击提示。
func can_use_hint() -> bool:
	return should_show() and active_hint.is_empty() and count(PROP_HINT) > 0 and not find_hint_guidance().is_empty()


## 是否可以点击撤回。
func can_use_undo() -> bool:
	return should_show() and count(PROP_UNDO) > 0 and not undo_stack.is_empty()


## 消耗一次提示，并显示下一步可行动作的教程式遮罩。
func use_hint() -> bool:
	if not active_hint.is_empty() or count(PROP_HINT) <= 0:
		return false
	var guidance := find_hint_guidance()
	if guidance.is_empty():
		return false
	counts[PROP_HINT] = count(PROP_HINT) - 1
	active_hint = guidance
	game._render()
	return true


## 消耗一次撤回，恢复到上一个正式动作之前的局面。
func use_undo() -> bool:
	if not can_use_undo():
		return false
	var snapshot: Dictionary = undo_stack.pop_back()
	counts[PROP_UNDO] = count(PROP_UNDO) - 1
	active_hint.clear()
	_restore_snapshot(snapshot)
	game.status_text = "已撤回"
	game._render()
	return true


## 正式动作改变局面前调用，记录可撤回快照。
func push_undo_snapshot() -> void:
	if not _round_props_enabled():
		return
	undo_stack.append(_make_snapshot())
	if undo_stack.size() > MAX_UNDO_HISTORY:
		undo_stack.remove_at(0)


## 如果动作预判后最终失败，撤掉刚刚压入的快照，避免出现空撤回。
func discard_latest_undo_snapshot() -> void:
	if not undo_stack.is_empty():
		undo_stack.pop_back()


## 成功动作、重开或回首页时隐藏当前提示。
func clear_hint() -> void:
	active_hint.clear()


## 当前正在展示的提示。
func hint_guidance() -> Dictionary:
	return active_hint


## 判断当前是否处于允许道具参与的普通局流程。
func _round_props_enabled() -> bool:
	return game.tutorial_completed \
		and not game.menu_active \
		and not game.game_over \
		and not game.settings_menu_open \
		and not game._tutorial_active()


## 搜索当前局面的一步合法提示。优先给出可移动动作，没有可移动动作时再提示抽牌/洗牌。
func find_hint_guidance() -> Dictionary:
	var move_hint: Dictionary = _find_move_hint()
	if not move_hint.is_empty():
		return move_hint
	if game.deck.size() > 0:
		return {"gesture": "tap", "source": {"kind": "deck"}, "target": {"kind": "draw_top"}}
	if game.draw_stack.size() > 0:
		return {"gesture": "tap", "source": {"kind": "deck"}, "target": {"kind": "deck"}}
	return {}


func _find_move_hint() -> Dictionary:
	if not game.draw_stack.is_empty():
		var draw_selection: Dictionary = game._selection_for_draw(game.draw_stack.size() - 1)
		var draw_hint: Dictionary = _hint_for_selection(draw_selection)
		if not draw_hint.is_empty():
			return draw_hint
	for col_idx in range(game.columns.size()):
		var column: Array = game.columns[col_idx]
		if column.is_empty():
			continue
		var selection: Dictionary = game._selection_for_board(col_idx, column.size() - 1)
		var board_hint: Dictionary = _hint_for_selection(selection)
		if not board_hint.is_empty():
			return board_hint
	return {}


func _hint_for_selection(selection: Dictionary) -> Dictionary:
	if selection.is_empty():
		return {}
	var source: Dictionary = _source_ref_for_selection(selection)
	var active_target: Dictionary = _active_category_target(selection)
	if not active_target.is_empty():
		return {"gesture": "drag", "source": source, "target": active_target}
	var empty_category_target: Dictionary = _empty_category_target(selection)
	if not empty_category_target.is_empty():
		return {"gesture": "drag", "source": source, "target": empty_category_target}
	var board_target: Dictionary = _board_column_target(selection)
	if not board_target.is_empty():
		return {"gesture": "drag", "source": source, "target": board_target}
	return {}


func _source_ref_for_selection(selection: Dictionary) -> Dictionary:
	if selection.get("source", "") == "draw":
		return {"kind": "draw_top"}
	return {
		"kind": "board_group",
		"col": int(selection.get("col", 0)),
		"card_name": _first_card_name(selection.get("cards", [])),
	}


func _active_category_target(selection: Dictionary) -> Dictionary:
	var cards: Array = selection.get("cards", [])
	var category := _group_category(cards)
	if category == "" or _group_has_category(cards) or not game.active_categories.has(category):
		return {}
	return {"kind": "active_category", "category": category}


func _empty_category_target(selection: Dictionary) -> Dictionary:
	var cards: Array = selection.get("cards", [])
	var category := _group_category(cards)
	if category == "" or not _group_has_category(cards) or game.active_categories.has(category):
		return {}
	if not _all_cards_belong_to_category(cards, category):
		return {}
	var slot := _first_empty_category_slot()
	if slot < 0:
		return {}
	return {"kind": "category_empty", "slot": slot}


func _board_column_target(selection: Dictionary) -> Dictionary:
	for col_idx in range(game.columns.size()):
		if _can_move_to_column(selection, col_idx):
			return {"kind": "board_column", "col": col_idx}
	return {}


func _can_move_to_column(selection: Dictionary, col_idx: int) -> bool:
	var cards: Array = selection.get("cards", [])
	if cards.is_empty():
		return false
	if selection.get("source", "") == "board" and int(selection.get("col", -1)) == col_idx:
		return false
	var target: Array = game.columns[col_idx]
	if target.is_empty():
		return true
	var last: Dictionary = target[target.size() - 1]
	return bool(last.get("face_up", false)) \
		and String(last.get("type", "")) == "word" \
		and String(last.get("category", "")) == _group_category(cards)


func _first_empty_category_slot() -> int:
	for i in range(game.MAX_CATEGORY_SLOTS):
		if not game._category_slot_occupied(i):
			return i
	return -1


func _group_category(cards: Array) -> String:
	if cards.is_empty():
		return ""
	return String(cards[0].get("category", ""))


func _group_has_category(cards: Array) -> bool:
	for card in cards:
		if String(card.get("type", "")) == "category":
			return true
	return false


func _all_cards_belong_to_category(cards: Array, category: String) -> bool:
	for card in cards:
		if String(card.get("category", "")) != category:
			return false
	return true


func _first_card_name(cards: Array) -> String:
	if cards.is_empty():
		return ""
	return String(cards[0].get("name", ""))


func _make_snapshot() -> Dictionary:
	return {
		"deck": game.deck.duplicate(true),
		"draw_stack": game.draw_stack.duplicate(true),
		"columns": game.columns.duplicate(true),
		"active_categories": game.active_categories.duplicate(true),
		"active_order": game.active_order.duplicate(true),
		"steps_left": game.steps_left,
		"status_text": game.status_text,
		"game_over": game.game_over,
		"next_card_id": game.next_card_id,
	}


func _restore_snapshot(snapshot: Dictionary) -> void:
	game._clear_transient_interaction_state()
	game.deck = snapshot.get("deck", []).duplicate(true)
	game.draw_stack = snapshot.get("draw_stack", []).duplicate(true)
	game.columns = snapshot.get("columns", []).duplicate(true)
	game.active_categories = snapshot.get("active_categories", {}).duplicate(true)
	game.active_order = snapshot.get("active_order", []).duplicate(true)
	game.steps_left = int(snapshot.get("steps_left", game.steps_left))
	game.status_text = String(snapshot.get("status_text", game.status_text))
	game.game_over = bool(snapshot.get("game_over", false))
	game.next_card_id = int(snapshot.get("next_card_id", game.next_card_id))
	game.settings_menu_open = false
	game.selected.clear()
	game.previous_card_positions.clear()
	game.pending_spawn_positions.clear()
