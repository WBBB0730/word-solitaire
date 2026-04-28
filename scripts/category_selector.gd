## 为每局选择类别，并过滤容易让玩家误判归属的组合。
## 例如不同类别里出现共享强首字/尾字的词语。
class_name CategorySelector
extends RefCounted

## 太常见、太宽泛的字，不应该阻止两个类别同局出现。
const WEAK_CONFLICT_TOKENS := ["子", "色", "人", "师", "家", "具", "品", "类", "术", "车", "机"]

## 每类进入单局时最少抽取多少张词语牌。
const MIN_WORDS_PER_CATEGORY := 3

## 每类进入单局时最多抽取多少张词语牌。
const MAX_WORDS_PER_CATEGORY := 8

## 同一类别选定词数后，最多尝试多少次随机抽词来避开跨类别冲突。
const WORD_SAMPLE_ATTEMPTS := 16

## 随机尝试选类别的次数，最后取其中词数分布较好的一组。
const SELECTION_ATTEMPTS := 60

## 如果可行，优先让一局覆盖 3 到 8 的全部词数长度。
const TARGET_LENGTH_VARIETY := 6

## 返回一局使用的完整类别集合。
static func select_categories_for_game(
		category_pool: Dictionary,
		category_count: int,
		max_eight_word_categories: int,
		max_seven_word_categories: int,
		category_conflict_groups := []
) -> Dictionary:
	var best_selection := {}
	var best_score := -999999
	for attempt in range(SELECTION_ATTEMPTS):
		var selection := _select_category_candidate(
			category_pool,
			category_count,
			max_eight_word_categories,
			max_seven_word_categories,
			category_conflict_groups
		)
		var score := word_count_distribution_score(selection)
		if selection.size() == category_count and score > best_score:
			best_selection = selection
			best_score = score
		if selection.size() == category_count and word_count_variety(selection) >= TARGET_LENGTH_VARIETY:
			break
	return best_selection


## 生成一次候选类别集合，外层会多次尝试后择优。
static func _select_category_candidate(
		category_pool: Dictionary,
		category_count: int,
		max_eight_word_categories: int,
		max_seven_word_categories: int,
		category_conflict_groups := []
) -> Dictionary:
	var names: Array = category_pool.keys()
	names.shuffle()
	var target_word_counts := target_word_counts_for_game(category_pool, category_count, max_eight_word_categories, max_seven_word_categories)
	var selected_categories := {}
	var used_words := {}
	var used_conflict_tokens := {}
	var blocked_categories := {}
	var used_category_names := {}

	for target_word_count in target_word_counts:
		var candidates := names.duplicate()
		candidates.shuffle()
		for category in candidates:
			if selected_categories.has(category):
				continue
			if used_words.has(category):
				continue
			if not category_conflict_groups_are_available(category, blocked_categories):
				continue
			var selected_words := sample_available_words_for_category(
				category,
				category_pool,
				used_words,
				used_conflict_tokens,
				used_category_names,
				target_word_count
			)
			if selected_words.is_empty():
				continue
			selected_categories[category] = selected_words
			used_category_names[category] = true
			mark_category_words_used(category, category_pool, used_words, used_conflict_tokens, category_conflict_groups, blocked_categories, selected_words)
			break
	return selected_categories


## 控制长类别出现数量，避免单局难度过高。
static func category_length_is_available(
		category: String,
		category_pool: Dictionary,
		selected_categories: Dictionary,
		max_eight_word_categories: int,
		max_seven_word_categories: int
) -> bool:
	return not candidate_word_counts_for_category(
		category,
		category_pool,
		selected_categories,
		max_eight_word_categories,
		max_seven_word_categories
	).is_empty()


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


## 为选择结果打分：先追求长度覆盖，再追求各长度数量均衡。
static func word_count_distribution_score(selection: Dictionary) -> int:
	if selection.is_empty():
		return -999999
	var counts := {}
	var max_count := 0
	for category in selection.keys():
		var length: int = selection[category].size()
		counts[length] = int(counts.get(length, 0)) + 1
		max_count = max(max_count, counts[length])
	return word_count_variety(selection) * 100 - max_count


## 生成本局目标词数。难度先由槽位决定，源词数较少的类别不能把长槽位降级。
static func target_word_counts_for_game(category_pool: Dictionary, category_count: int, max_eight_word_categories: int, max_seven_word_categories: int) -> Array:
	var counts := []
	var used_length_counts := {}
	for length in range(MIN_WORDS_PER_CATEGORY, MAX_WORDS_PER_CATEGORY + 1):
		if length == 8 and max_eight_word_categories <= 0:
			continue
		if length == 7 and max_seven_word_categories <= 0:
			continue
		if counts.size() < category_count:
			counts.append(length)
			used_length_counts[length] = 1

	while counts.size() < category_count:
		var candidates := []
		for length in range(MIN_WORDS_PER_CATEGORY, MAX_WORDS_PER_CATEGORY + 1):
			if length == 8 and int(used_length_counts.get(length, 0)) >= max_eight_word_categories:
				continue
			if length == 7 and int(used_length_counts.get(length, 0)) >= max_seven_word_categories:
				continue
			candidates.append(length)
		if candidates.is_empty():
			break
		candidates = prioritize_length_counts(candidates, used_length_counts)
		var length: int = candidates[0]
		counts.append(length)
		used_length_counts[length] = int(used_length_counts.get(length, 0)) + 1

	counts = enforce_target_word_count_capacity(counts, category_pool, max_eight_word_categories, max_seven_word_categories)
	counts.shuffle()
	return counts


## 根据源牌库容量修正目标槽位。源词数较少的类别只参与能承接的短槽，不会把长槽临时降级。
static func enforce_target_word_count_capacity(
		counts: Array,
		category_pool: Dictionary,
		max_eight_word_categories: int,
		max_seven_word_categories: int
) -> Array:
	var adjusted := counts.duplicate()
	_limit_exact_length_count(adjusted, 8, max_eight_word_categories)
	_limit_exact_length_count(adjusted, 7, max_seven_word_categories)
	for length in range(MAX_WORDS_PER_CATEGORY, MIN_WORDS_PER_CATEGORY, -1):
		var capacity := candidate_category_count_for_length(category_pool, length)
		while count_lengths_at_least(adjusted, length) > capacity:
			var index := index_of_smallest_length_at_least(adjusted, length)
			if index < 0:
				break
			adjusted[index] = length - 1
	return adjusted


## 限制精确长度数量，例如 8 词类别最多 1 组。
static func _limit_exact_length_count(counts: Array, length: int, limit: int) -> void:
	while exact_length_count(counts, length) > limit:
		var index := counts.find(length)
		if index < 0:
			return
		counts[index] = length - 1


## 统计目标槽位中至少为某个长度的数量。
static func count_lengths_at_least(counts: Array, length: int) -> int:
	var count := 0
	for value in counts:
		if int(value) >= length:
			count += 1
	return count


## 统计目标槽位中正好为某个长度的数量。
static func exact_length_count(counts: Array, length: int) -> int:
	var count := 0
	for value in counts:
		if int(value) == length:
			count += 1
	return count


## 找出大于等于指定长度的最短槽位，容量不足时优先降低它，保留高难度槽位。
static func index_of_smallest_length_at_least(counts: Array, length: int) -> int:
	var best_index := -1
	var best_value := 999999
	for i in range(counts.size()):
		var value := int(counts[i])
		if value >= length and value < best_value:
			best_index = i
			best_value = value
	return best_index


## 统计源牌库中有多少分类能承接某个词数槽位。
static func candidate_category_count_for_length(category_pool: Dictionary, length: int) -> int:
	var count := 0
	for category in category_pool.keys():
		if category_pool[category].size() >= length:
			count += 1
	return count


## 优先补出现次数少的目标长度，让 3-8 在单局内尽量均匀。
static func prioritize_length_counts(lengths: Array, used_length_counts: Dictionary) -> Array:
	var remaining := lengths.duplicate()
	remaining.shuffle()
	var prioritized := []
	while not remaining.is_empty():
		var best_index := 0
		var best_count := 999999
		for i in range(remaining.size()):
			var length: int = remaining[i]
			var count := int(used_length_counts.get(length, 0))
			if count < best_count:
				best_index = i
				best_count = count
		prioritized.append(remaining[best_index])
		remaining.remove_at(best_index)
	return prioritized


## 从某个大分类里随机抽出本局槽位要求的固定数量词语牌。
static func sample_available_words_for_category(
		category: String,
		category_pool: Dictionary,
		used_words: Dictionary,
		used_conflict_tokens: Dictionary,
		used_category_names: Dictionary,
		target_word_count: int
) -> Array:
	if category_pool[category].size() < target_word_count:
		return []
	for attempt in range(WORD_SAMPLE_ATTEMPTS):
		var sample := random_word_sample(category_pool[category], target_word_count)
		if not words_are_available(sample, used_words):
			continue
		if not words_do_not_match_category_names(sample, used_category_names):
			continue
		if not conflict_tokens_are_available_for_words(sample, used_conflict_tokens):
			continue
		return sample
	return []


## 返回该类别当前可抽取的词数候选，并优先补齐还没出现过的长度。
static func candidate_word_counts_for_category(
		category: String,
		category_pool: Dictionary,
		selected_categories: Dictionary,
		max_eight_word_categories: int,
		max_seven_word_categories: int
) -> Array:
	var max_count: int = min(MAX_WORDS_PER_CATEGORY, category_pool[category].size())
	if max_count < MIN_WORDS_PER_CATEGORY:
		return []

	var counts := []
	for length in range(MIN_WORDS_PER_CATEGORY, max_count + 1):
		if length == 8 and selected_category_length_count(selected_categories, 8) >= max_eight_word_categories:
			continue
		if length == 7 and selected_category_length_count(selected_categories, 7) >= max_seven_word_categories:
			continue
		counts.append(length)

	return prioritize_word_counts(counts, selected_categories)


## 让当前出现次数少的词数优先被使用，避免单局全部同长度。
static func prioritize_word_counts(counts: Array, selected_categories: Dictionary) -> Array:
	var remaining := counts.duplicate()
	remaining.shuffle()
	var prioritized := []
	while not remaining.is_empty():
		var best_index := 0
		var best_count := 999999
		for i in range(remaining.size()):
			var length: int = remaining[i]
			var count := selected_category_length_count(selected_categories, length)
			if count < best_count:
				best_index = i
				best_count = count
		prioritized.append(remaining[best_index])
		remaining.remove_at(best_index)
	return prioritized


## 从源分类词库里随机取指定数量的词。
static func random_word_sample(words: Array, word_count: int) -> Array:
	var shuffled := words.duplicate()
	shuffled.shuffle()
	var sample := []
	for i in range(word_count):
		sample.append(shuffled[i])
	return sample


## 避免同一个词在同一局里属于两个类别。
static func category_words_are_available(category: String, category_pool: Dictionary, used_words: Dictionary) -> bool:
	return words_are_available(category_pool[category], used_words)


## 避免同一个词在同一局里属于两个类别。
static func words_are_available(words: Array, used_words: Dictionary) -> bool:
	for word in words:
		if used_words.has(word):
			return false
	return true


## 避免词语牌正好等于另一张已选类别牌的名字。
static func words_do_not_match_category_names(words: Array, used_category_names: Dictionary) -> bool:
	for word in words:
		if used_category_names.has(word):
			return false
	return true


## 避免跨类别近似词同局出现，例如“茶几”和“茶盘”。
static func category_conflict_tokens_are_available(category: String, category_pool: Dictionary, used_conflict_tokens: Dictionary) -> bool:
	return conflict_tokens_are_available_for_words(category_pool[category], used_conflict_tokens)


## 避免一组已抽出的词和本局已有词产生跨类别近似混淆。
static func conflict_tokens_are_available_for_words(words: Array, used_conflict_tokens: Dictionary) -> bool:
	for word in words:
		for token in word_conflict_tokens(word):
			if used_conflict_tokens.has(token):
				return false
	return true


## 避免手写冲突组中的类别同局出现。
static func category_conflict_groups_are_available(category: String, blocked_categories: Dictionary) -> bool:
	return not blocked_categories.has(category)


## 记录已选类别的完整词和混淆标记。
static func mark_category_words_used(
		category: String,
		category_pool: Dictionary,
		used_words: Dictionary,
		used_conflict_tokens: Dictionary,
		category_conflict_groups := [],
		blocked_categories := {},
		selected_words := []
) -> void:
	var words: Array = selected_words if not selected_words.is_empty() else category_pool[category]
	for word in words:
		used_words[word] = true
		for token in word_conflict_tokens(word):
			used_conflict_tokens[token] = true
	for group in category_conflict_groups:
		if category in group:
			for blocked_category in group:
				blocked_categories[blocked_category] = category


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
