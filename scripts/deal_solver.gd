## 模拟合法移动，用来验证随机牌局能否完成，并估算合理步数。
## 求解器只处理紧凑的卡牌编号，不直接接触界面节点和拖拽状态。
class_name DealSolver
extends RefCounted

## 当前游戏场景，提供卡牌字典、类别数据和求解器参数。
var game: Node


func _init(game_scene: Node) -> void:
	game = game_scene


## 多次运行带随机扰动的深度优先搜索，返回成功样本的平均步数。
func solve(max_solution_steps := -1) -> Dictionary:
	if max_solution_steps < 0:
		max_solution_steps = int(game.SOLVER_MAX_SOLUTION_STEPS)
	var sample_count := randi_range(int(game.SOLVER_DFS_SAMPLE_MIN), int(game.SOLVER_DFS_SAMPLE_MAX))
	var solved_steps: Array[int] = []
	var total_states := 0

	for sample_idx in range(sample_count):
		var state_budget: int = max(1200, int(int(game.SOLVER_MAX_STATES_PER_DEAL) / sample_count))
		var result := solve_dfs(max_solution_steps, state_budget)
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


## 在给定状态预算内运行一次深度优先搜索。
func solve_dfs(max_solution_steps := -1, state_budget := -1) -> Dictionary:
	if max_solution_steps < 0:
		max_solution_steps = int(game.SOLVER_MAX_SOLUTION_STEPS)
	if state_budget < 0:
		state_budget = int(game.SOLVER_MAX_STATES_PER_DEAL)

	var card_info := _card_info()
	var initial_state := _initial_state()
	var stack: Array[Dictionary] = [{"state": initial_state, "steps": 0}]
	var best_seen := {}
	var states_checked := 0

	while not stack.is_empty() and states_checked < state_budget:
		var entry: Dictionary = stack.pop_back()
		var state: Dictionary = entry["state"]
		var steps: int = int(entry["steps"])
		var key := _state_key(state)
		if best_seen.has(key) and int(best_seen[key]) <= steps:
			continue
		best_seen[key] = steps
		states_checked += 1

		if _is_win(state):
			return {"solved": true, "steps": steps, "states": states_checked}
		if steps >= max_solution_steps:
			continue

		var next_entries := _next_entries(state, card_info, steps)
		_randomize_entry_order(next_entries)
		for next_entry in next_entries:
			stack.append(next_entry)

	return {"solved": false, "steps": 0, "states": states_checked}


## 给候选步骤加随机扰动，让多次深度优先搜索探索不同但合理的路径。
func _randomize_entry_order(entries: Array[Dictionary]) -> void:
	for entry in entries:
		entry["rank"] = float(entry["priority"]) + randf_range(-float(game.SOLVER_DFS_PRIORITY_JITTER), float(game.SOLVER_DFS_PRIORITY_JITTER))
	entries.shuffle()
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["rank"]) < float(b["rank"])
	)


## 从牌堆和 4 区牌建立编号到卡牌元信息的映射。
func _card_info() -> Dictionary:
	var info := {}
	for card in game.deck:
		_add_card_info(info, card)
	for column in game.columns:
		for card in column:
			_add_card_info(info, card)
	return info


## 写入单张牌的求解器元信息。
func _add_card_info(info: Dictionary, card: Dictionary) -> void:
	info[int(card["id"])] = {
		"type": card["type"],
		"name": card["name"],
		"category": card["category"],
	}


## 将实时牌局转换成紧凑的搜索状态。
func _initial_state() -> Dictionary:
	var state := {
		"deck": [],
		"draw": [],
		"cols": [],
		"active": {},
	}
	for card in game.deck:
		state["deck"].append(int(card["id"]))
	for column in game.columns:
		var solver_col: Array[int] = []
		for card in column:
			var card_id := int(card["id"])
			solver_col.append(card_id if bool(card["face_up"]) else -card_id)
		state["cols"].append(solver_col)
	return state


## 返回当前求解状态的一步合法后继。
func _next_entries(state: Dictionary, card_info: Dictionary, steps: int) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	_add_source_moves(entries, state, card_info, steps)
	var deck_cards: Array = state["deck"]
	if not deck_cards.is_empty():
		var next_state := _clone_state(state)
		var next_deck: Array = next_state["deck"]
		var next_draw: Array = next_state["draw"]
		next_draw.append(int(next_deck.pop_back()))
		entries.append({"state": next_state, "steps": steps + 1, "priority": 1})
	return entries


## 加入来自 1 区顶牌和 4 区每列可移动底部组的移动。
func _add_source_moves(entries: Array[Dictionary], state: Dictionary, card_info: Dictionary, steps: int) -> void:
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
		var start := _group_start_index(col, card_info)
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
		var has_progress_move := _has_category_progress_move(state, card_info, source)
		_add_category_moves(entries, state, card_info, source, steps)
		# 能推进收集时，先不生成等价的临时停靠移动，避免浪费搜索预算。
		if not has_progress_move:
			_add_column_moves(entries, state, card_info, source, steps)


## 判断这个来源是否能直接推进已有或新开的类别。
func _has_category_progress_move(state: Dictionary, card_info: Dictionary, source: Dictionary) -> bool:
	var group: Array = source["group"]
	if group.is_empty():
		return false
	var category := _group_category(group, card_info)
	var active: Dictionary = state["active"]
	var has_category := _group_has_category(group, card_info)
	if not has_category and active.has(category):
		return true
	return has_category \
		and not active.has(category) \
		and active.size() < int(game.MAX_CATEGORY_SLOTS) \
		and _group_is_single_category(group, category, card_info)


## 加入移动到 3 区的合法步骤。
func _add_category_moves(entries: Array[Dictionary], state: Dictionary, card_info: Dictionary, source: Dictionary, steps: int) -> void:
	var group: Array = source["group"]
	if group.is_empty():
		return
	var category := _group_category(group, card_info)
	var active: Dictionary = state["active"]
	var has_category := _group_has_category(group, card_info)

	if not has_category and active.has(category):
		var next_state := _clone_state(state)
		_remove_source(next_state, source)
		var completed := _collect_words(next_state, group, card_info)
		entries.append({"state": next_state, "steps": steps + 1, "priority": 22 if completed else 14})
		return

	if has_category and not active.has(category) and active.size() < int(game.MAX_CATEGORY_SLOTS) and _group_is_single_category(group, category, card_info):
		var next_state := _clone_state(state)
		_remove_source(next_state, source)
		next_state["active"][category] = {}
		var completed := _collect_words(next_state, group, card_info)
		entries.append({"state": next_state, "steps": steps + 1, "priority": 20 if completed else 12})


## 加入移动到 4 区列中的合法步骤。
func _add_column_moves(entries: Array[Dictionary], state: Dictionary, card_info: Dictionary, source: Dictionary, steps: int) -> void:
	var group: Array = source["group"]
	if group.is_empty():
		return
	var category := _group_category(group, card_info)
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
		elif not _can_stack_on_column(target, category, card_info):
			continue

		var next_state := _clone_state(state)
		var reveals_card := _source_reveals_card(next_state, source)
		_remove_source(next_state, source)
		var next_cols: Array = next_state["cols"]
		var next_target: Array = next_cols[target_col]
		for card_id in group:
			next_target.append(abs(int(card_id)))
		var priority := 8 if reveals_card else 4
		if not target_is_empty:
			priority += 2
		entries.append({"state": next_state, "steps": steps + 1, "priority": priority})


## 找到 4 区某列可移动底部组的第一张牌下标。
func _group_start_index(col: Array, card_info: Dictionary) -> int:
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
		# 类别牌会封口；词语牌不能跨过类别牌继续组成可移动组。
		if last_info["type"] == "word" and info["type"] == "category":
			break
		start = i
	return start


## 判断指定类别的整组牌能否堆到目标列上。
func _can_stack_on_column(target: Array, category: String, card_info: Dictionary) -> bool:
	if target.is_empty():
		return true
	var last_value := int(target[target.size() - 1])
	if last_value < 0:
		return false
	var info: Dictionary = card_info[abs(last_value)]
	return info["type"] == "word" and info["category"] == category


## 判断移走来源牌组后是否会翻开一张盖牌。
func _source_reveals_card(state: Dictionary, source: Dictionary) -> bool:
	if source["source"] != "board":
		return false
	var cols: Array = state["cols"]
	var col: Array = cols[int(source["source_col"])]
	var start := int(source["start"])
	return start > 0 and int(col[start - 1]) < 0


## 从来源移除一组牌，并翻开新露出的 4 区底牌。
func _remove_source(state: Dictionary, source: Dictionary) -> void:
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


## 将词语计入 3 区类别；如果集齐则移除该类别。
func _collect_words(state: Dictionary, group: Array, card_info: Dictionary) -> bool:
	if group.is_empty():
		return false
	var category := _group_category(group, card_info)
	var active: Dictionary = state["active"]
	if not active.has(category):
		return false
	var collected: Dictionary = active[category]
	for card_id in group:
		var info: Dictionary = card_info[abs(int(card_id))]
		if info["type"] == "word" and info["category"] == category:
			collected[info["name"]] = true
	if collected.size() >= game.categories[category].size():
		active.erase(category)
		return true
	return false


## 返回牌组所属类别。
func _group_category(group: Array, card_info: Dictionary) -> String:
	if group.is_empty():
		return ""
	var info: Dictionary = card_info[abs(int(group[0]))]
	return info["category"]


## 判断牌组中是否包含类别牌。
func _group_has_category(group: Array, card_info: Dictionary) -> bool:
	for card_id in group:
		var info: Dictionary = card_info[abs(int(card_id))]
		if info["type"] == "category":
			return true
	return false


## 判断牌组中所有牌是否都属于同一类别。
func _group_is_single_category(group: Array, category: String, card_info: Dictionary) -> bool:
	for card_id in group:
		var info: Dictionary = card_info[abs(int(card_id))]
		if info["category"] != category:
			return false
	return true


## 深拷贝搜索状态里的可变数组和字典。
func _clone_state(state: Dictionary) -> Dictionary:
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


## 判断求解状态是否已经清空所有区域。
func _is_win(state: Dictionary) -> bool:
	if not state["deck"].is_empty() or not state["draw"].is_empty() or not state["active"].is_empty():
		return false
	for col in state["cols"]:
		if not col.is_empty():
			return false
	return true


## 构建规范化状态键。列顺序会排序，因为空列停靠顺序不影响可解性；
## 如果不合并这类等价状态，搜索状态数量会膨胀得很快。
func _state_key(state: Dictionary) -> String:
	var parts: Array[String] = []
	parts.append(_join_ints(state["deck"]))
	parts.append(_join_ints(state["draw"]))
	var column_parts: Array[String] = []
	for col in state["cols"]:
		column_parts.append(_join_ints(col))
	column_parts.sort()
	parts.append(_join_strings(column_parts))
	var active_keys: Array = state["active"].keys()
	active_keys.sort()
	var active_parts: Array[String] = []
	for category in active_keys:
		var collected: Dictionary = state["active"][category]
		var words: Array = collected.keys()
		words.sort()
		active_parts.append(str(category) + ":" + _join_strings(words))
	parts.append(_join_strings(active_parts))
	return "|".join(PackedStringArray(parts))


func _join_ints(values: Array) -> String:
	var strings: Array[String] = []
	for value in values:
		strings.append(str(int(value)))
	return ",".join(PackedStringArray(strings))


func _join_strings(values: Array) -> String:
	var strings: Array[String] = []
	for value in values:
		strings.append(str(value))
	return ",".join(PackedStringArray(strings))
