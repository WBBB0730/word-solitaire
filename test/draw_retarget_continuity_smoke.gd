extends SceneTree

var scene: Node
var checked := false


func _initialize() -> void:
	scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)


func _process(_delta: float) -> bool:
	if checked:
		return false
	checked = true
	scene._ready()
	scene.menu_active = false
	scene.deck = [
		scene._word("苹果", false),
		scene._word("香蕉", false),
		scene._word("葡萄", false),
		scene._word("桃子", false),
	]
	scene.draw_stack.clear()
	scene.previous_card_positions.clear()
	scene._render()

	scene._handle_deck_pressed()
	scene._handle_deck_pressed()
	scene._handle_deck_pressed()
	var tracked_card_id: int = scene.draw_stack[1]["id"]
	var tracked_node = scene.draw_animation_nodes.get(tracked_card_id)
	if not is_instance_valid(tracked_node):
		push_error("Draw retarget continuity smoke failed: tracked animated card missing")
		quit(1)
		return false

	scene._process(scene.DRAW_ANIM_TIME * 0.25)
	var before_retarget: Vector2 = tracked_node.position
	scene._handle_deck_pressed()
	var after_retarget: Vector2 = tracked_node.position
	if before_retarget.distance_to(after_retarget) > 0.1:
		push_error("Draw retarget continuity smoke failed: retarget snapped the active card")
		quit(1)
		return false
	var flight: Dictionary = scene.draw_flights[tracked_card_id]
	var sibling_card_id: int = scene.draw_stack[2]["id"]
	var sibling_flight: Dictionary = scene.draw_flights[sibling_card_id]
	if abs(float(flight.get("move_time", 0.0)) - float(sibling_flight.get("move_time", 0.0))) > 0.001:
		push_error("Draw retarget continuity smoke failed: visible draw cards do not refill in sync")
		quit(1)
		return false
	if float(flight.get("move_elapsed", -1.0)) != 0.0:
		push_error("Draw retarget continuity smoke failed: retarget move timer was not restarted")
		quit(1)
		return false
	var move_time: float = float(flight.get("move_time", 0.0))
	if move_time < scene.DRAW_RETARGET_TIME or move_time > scene.DRAW_ANIM_TIME:
		push_error("Draw retarget continuity smoke failed: retarget move duration is wrong")
		quit(1)
		return false

	scene._process(move_time * 0.5)
	var midway: Vector2 = tracked_node.position
	var target: Vector2 = flight["target"]
	if midway.distance_to(before_retarget) < 0.5:
		push_error("Draw retarget continuity smoke failed: retargeted card did not continue moving")
		quit(1)
		return false
	if midway.distance_to(target) < 0.5:
		push_error("Draw retarget continuity smoke failed: retargeted card arrived too abruptly")
		quit(1)
		return false

	print("DRAW_RETARGET_CONTINUITY_SMOKE_PASS")
	quit(0)
	return false
