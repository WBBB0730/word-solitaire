## 为每局选择类别，并过滤容易让玩家误判归属的组合。
## 例如不同类别里出现共享强首字/尾字的词语。
class_name CategorySelector
extends RefCounted

## 太常见、太宽泛的字，不应该阻止两个类别同局出现。
const WEAK_CONFLICT_TOKENS := ["子", "色", "人", "师", "家", "具", "品", "类", "术", "车", "机"]

## 随机尝试选类别的次数，最后取其中词数分布较好的一组。
const SELECTION_ATTEMPTS := 30

## 如果可行，优先让一局里出现至少这么多种类别长度。
const TARGET_LENGTH_VARIETY := 4

## 第一轮选择会尽量避免过早重复类别长度。
const FIRST_PASS_LENGTH_TARGET := 5


## 返回一局使用的完整类别集合。
static func select_categories_for_game(
		category_pool: Dictionary,
		category_count: int,
		max_eight_word_categories: int,
		max_seven_word_categories: int
) -> Dictionary:
	var best_selection := {}
	var best_variety := -1
	for attempt in range(SELECTION_ATTEMPTS):
		var selection := _select_category_candidate(
			category_pool,
			category_count,
			max_eight_word_categories,
			max_seven_word_categories
		)
		var variety := word_count_variety(selection)
		if selection.size() == category_count and variety > best_variety:
			best_selection = selection
			best_variety = variety
		if best_variety >= TARGET_LENGTH_VARIETY:
			break
	return best_selection


## 生成一次候选类别集合，外层会多次尝试后择优。
static func _select_category_candidate(
		category_pool: Dictionary,
		category_count: int,
		max_eight_word_categories: int,
		max_seven_word_categories: int
) -> Dictionary:
	var names: Array = category_pool.keys()
	names.shuffle()
	var selected_categories := {}
	var used_words := {}
	var used_conflict_tokens := {}
	var used_lengths := {}

	for category in names:
		if selected_categories.size() >= category_count:
			break
		if used_lengths.has(category_pool[category].size()) and used_lengths.size() < FIRST_PASS_LENGTH_TARGET:
			continue
		if not category_length_is_available(category, category_pool, selected_categories, max_eight_word_categories, max_seven_word_categories):
			continue
		if not category_words_are_available(category, category_pool, used_words):
			continue
		if not category_conflict_tokens_are_available(category, category_pool, used_conflict_tokens):
			continue
		selected_categories[category] = category_pool[category].duplicate()
		used_lengths[category_pool[category].size()] = true
		mark_category_words_used(category, category_pool, used_words, used_conflict_tokens)

	for category in names:
		if selected_categories.size() >= category_count:
			break
		if selected_categories.has(category):
			continue
		if not category_length_is_available(category, category_pool, selected_categories, max_eight_word_categories, max_seven_word_categories):
			continue
		if not category_words_are_available(category, category_pool, used_words):
			continue
		if not category_conflict_tokens_are_available(category, category_pool, used_conflict_tokens):
			continue
		selected_categories[category] = category_pool[category].duplicate()
		mark_category_words_used(category, category_pool, used_words, used_conflict_tokens)
	return selected_categories


## 控制长类别出现数量，避免单局难度过高。
static func category_length_is_available(
		category: String,
		category_pool: Dictionary,
		selected_categories: Dictionary,
		max_eight_word_categories: int,
		max_seven_word_categories: int
) -> bool:
	var length: int = category_pool[category].size()
	if length == 8:
		return selected_category_length_count(selected_categories, 8) < max_eight_word_categories
	if length == 7:
		return selected_category_length_count(selected_categories, 7) < max_seven_word_categories
	return true


## 统计已选类别中，指定词语数量的类别有几组。
static func selected_category_length_count(selected_categories: Dictionary, length: int) -> int:
	var count := 0
	for category in selected_categories.keys():
		if selected_categories[category].size() == length:
			count += 1
	return count


## 统计一组类别里出现了多少种不同词语数量。
static func word_count_variety(selection: Dictionary) -> int:
	var lengths := {}
	for category in selection.keys():
		lengths[selection[category].size()] = true
	return lengths.size()


## 避免同一个词在同一局里属于两个类别。
static func category_words_are_available(category: String, category_pool: Dictionary, used_words: Dictionary) -> bool:
	for word in category_pool[category]:
		if used_words.has(word):
			return false
	return true


## 避免跨类别近似词同局出现，例如“茶几”和“茶盘”。
static func category_conflict_tokens_are_available(category: String, category_pool: Dictionary, used_conflict_tokens: Dictionary) -> bool:
	for word in category_pool[category]:
		for token in word_conflict_tokens(word):
			if used_conflict_tokens.has(token):
				return false
	return true


## 记录已选类别的完整词和混淆标记。
static func mark_category_words_used(category: String, category_pool: Dictionary, used_words: Dictionary, used_conflict_tokens: Dictionary) -> void:
	for word in category_pool[category]:
		used_words[word] = true
		for token in word_conflict_tokens(word):
			used_conflict_tokens[token] = true


## 返回可能让两个词看起来有关联的强首字/尾字标记。
static func word_conflict_tokens(word: String) -> Array[String]:
	var tokens: Array[String] = []
	var clean_word := word.strip_edges()
	var length: int = clean_word.length()
	if length <= 0:
		return tokens
	if length == 1:
		tokens.append(clean_word)
		return tokens

	var first := clean_word.substr(0, 1)
	var last := clean_word.substr(length - 1, 1)
	if not is_weak_conflict_token(first):
		tokens.append(first)
	if first != last and not is_weak_conflict_token(last):
		tokens.append(last)
	return tokens


## 判断某个字是否太泛，泛到不适合作为混淆依据。
static func is_weak_conflict_token(token: String) -> bool:
	return token in WEAK_CONFLICT_TOKENS
