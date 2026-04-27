extends SceneTree


func _initialize() -> void:
	var started := Time.get_ticks_msec()
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	scene._ready()
	var elapsed := Time.get_ticks_msec() - started

	if not scene.last_solver_found:
		push_error("Solver smoke failed: generated deal was not verified as solvable")
		quit(1)
		return
	if scene.last_solver_steps <= 0:
		push_error("Solver smoke failed: solution step count was not recorded")
		quit(1)
		return
	if scene.steps_left < scene.last_solver_steps:
		push_error("Solver smoke failed: displayed steps are below solution steps")
		quit(1)
		return
	if scene.last_solver_attempts <= 0 or scene.last_solver_attempts > scene.SOLVER_MAX_DEAL_ATTEMPTS:
		push_error("Solver smoke failed: attempt count is out of range")
		quit(1)
		return

	print("SOLVER_SMOKE_PASS attempts=%d solution_steps=%d displayed_steps=%d states=%d elapsed_ms=%d" % [
		scene.last_solver_attempts,
		scene.last_solver_steps,
		scene.steps_left,
		scene.last_solver_states,
		elapsed,
	])
	quit(0)
