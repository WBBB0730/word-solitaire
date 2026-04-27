extends SceneTree


func _initialize() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	_load_two_move_solution(scene)

	var result: Dictionary = scene._solve_current_deal()
	if not bool(result.get("solved", false)):
		push_error("Solver randomized DFS smoke failed: controlled deal was not solved")
		quit(1)
		return
	if int(result.get("samples", 0)) < scene.SOLVER_DFS_SAMPLE_MIN:
		push_error("Solver randomized DFS smoke failed: not enough samples")
		quit(1)
		return
	if int(result.get("solved_samples", 0)) <= 0:
		push_error("Solver randomized DFS smoke failed: no successful samples")
		quit(1)
		return
	if int(result.get("steps", -1)) != 2:
		push_error("Solver randomized DFS smoke failed: expected average 2 steps, got " + str(result.get("steps", -1)))
		quit(1)
		return

	print("SOLVER_RANDOMIZED_DFS_SMOKE_PASS samples=%d solved=%d states=%d" % [
		int(result.get("samples", 0)),
		int(result.get("solved_samples", 0)),
		int(result.get("states", 0)),
	])
	quit(0)


func _load_two_move_solution(scene: Node) -> void:
	scene.categories = {"水果": ["苹果"]}
	scene.word_to_category = {"苹果": "水果"}
	scene.next_card_id = 1
	scene.deck.clear()
	scene.draw_stack.clear()
	scene.columns = [
		[scene._category("水果")],
		[scene._word("苹果")],
		[],
		[],
	]
	scene.active_categories.clear()
	scene.active_order.clear()
