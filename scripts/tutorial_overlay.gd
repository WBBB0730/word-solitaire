## 新手教学视觉层。
##
## 只负责把教学控制器的 source/target 引用渲染成高亮和手势动画；
## 不判断规则，不推进步骤，避免教程表现逻辑混进主游戏流程。
class_name TutorialOverlay
extends RefCounted

const MASK_COLOR := Color(0, 0, 0, 0.34)
const MASK_HOLE_RADIUS := 22.0

var game: Node


func _init(game_scene: Node) -> void:
	game = game_scene


## 根据当前步骤渲染教学高亮和手势，不显示任何规则文案。
func render(guidance: Dictionary) -> void:
	if guidance.is_empty():
		return
	var source_rect := _ref_rect(guidance.get("source", {}))
	var target_rect := _ref_rect(guidance.get("target", {}))
	_add_mask(_visible_rects([source_rect, target_rect]))
	if source_rect.size == Vector2.ZERO:
		return
	if String(guidance.get("gesture", "drag")) == "tap" or target_rect.size == Vector2.ZERO:
		_add_tap_hand(source_rect.get_center())
	else:
		_add_drag_hand(source_rect.get_center(), target_rect.get_center())


## 把教学控制器给出的抽象引用转换成当前布局下的实际高亮矩形。
func _ref_rect(ref: Dictionary) -> Rect2:
	match String(ref.get("kind", "")):
		"deck":
			return game._deck_rect()
		"draw_top":
			if game.draw_stack.is_empty():
				return Rect2()
			return Rect2(game._draw_card_position(game.draw_stack.size() - 1), Vector2(game.CARD_W, game.CARD_H))
		"board_column":
			return _board_column_focus_rect(int(ref.get("col", 0)))
		"board_group":
			var col_idx := int(ref.get("col", 0))
			if col_idx < 0 or col_idx >= game.columns.size() or game.columns[col_idx].is_empty():
				return Rect2()
			var start: int = game._group_start_index(game.columns[col_idx])
			if start < 0:
				start = game.columns[col_idx].size() - 1
			var pos := Vector2(game._column_x(col_idx), game._layout_y(game.BOARD_Y) + start * game.STACK_STEP)
			var height: float = game.CARD_H + float(max(0, game.columns[col_idx].size() - start - 1)) * game.STACK_STEP
			return Rect2(pos, Vector2(game.CARD_W, height))
		"category_empty":
			return game._category_slot_rect(int(ref.get("slot", 0)))
		"active_category":
			var category := String(ref.get("category", ""))
			for i in range(game.active_order.size()):
				if game.active_order[i] == category:
					return game._category_slot_rect(i)
			return Rect2()
		_:
			return Rect2()


## 教学里的 4 区目标只露出可见牌组范围，不使用正式拖放的整列扩展命中区。
func _board_column_focus_rect(col_idx: int) -> Rect2:
	if col_idx < 0 or col_idx >= game.columns.size():
		return Rect2()
	var x: float = game._column_x(col_idx)
	var y: float = game._layout_y(game.BOARD_Y)
	var column: Array = game.columns[col_idx]
	if column.is_empty():
		return Rect2(Vector2(x, y), Vector2(game.CARD_W, game.CARD_H))
	var height: float = game.CARD_H + float(max(0, column.size() - 1)) * game.STACK_STEP
	return Rect2(Vector2(x, y), Vector2(game.CARD_W, height))


## 过滤空矩形，并统一扩大一点留白，避免遮罩贴着卡牌边缘。
func _visible_rects(rects: Array[Rect2]) -> Array[Rect2]:
	var result: Array[Rect2] = []
	for rect in rects:
		if rect.size == Vector2.ZERO:
			continue
		result.append(rect.grow(14.0))
	return result


## 给不可操作区域加遮罩，只给当前允许的来源和目标区域留出矩形洞。
func _add_mask(holes: Array[Rect2]) -> void:
	var viewport_rect := Rect2(Vector2.ZERO, game.get_viewport_rect().size)
	if viewport_rect.size == Vector2.ZERO:
		return
	var clamped_holes: Array[Rect2] = []
	for hole in holes:
		var clipped := viewport_rect.intersection(hole)
		if clipped.size == Vector2.ZERO:
			continue
		clamped_holes.append(clipped)
	var mask := ColorRect.new()
	mask.set_meta("tutorial_guidance", true)
	mask.set_meta("tutorial_mask", true)
	mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mask.color = MASK_COLOR
	mask.position = viewport_rect.position
	mask.size = viewport_rect.size
	mask.z_index = 170
	mask.material = _make_mask_material(clamped_holes, viewport_rect.size)
	game.add_child(mask)


## 用 shader 做圆角挖空；最多需要 source/target 两个洞。
func _make_mask_material(holes: Array[Rect2], viewport_size: Vector2) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform vec4 hole0 = vec4(-10000.0, -10000.0, 0.0, 0.0);
uniform vec4 hole1 = vec4(-10000.0, -10000.0, 0.0, 0.0);
uniform int hole_count = 0;
uniform vec2 viewport_size = vec2(1.0, 1.0);
uniform float radius = 22.0;
uniform vec4 mask_color : source_color = vec4(0.0, 0.0, 0.0, 0.34);

bool inside_round_rect(vec2 p, vec4 rect_data) {
	if (p.x < rect_data.x || p.y < rect_data.y || p.x > rect_data.x + rect_data.z || p.y > rect_data.y + rect_data.w) {
		return false;
	}
	float r = min(radius, min(rect_data.z, rect_data.w) * 0.5);
	vec2 inner_min = rect_data.xy + vec2(r);
	vec2 inner_max = rect_data.xy + rect_data.zw - vec2(r);
	vec2 nearest = clamp(p, inner_min, inner_max);
	return distance(p, nearest) <= r;
}

void fragment() {
	vec2 p = UV * viewport_size;
	if ((hole_count > 0 && inside_round_rect(p, hole0)) || (hole_count > 1 && inside_round_rect(p, hole1))) {
		COLOR = vec4(0.0);
	} else {
		COLOR = mask_color;
	}
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("viewport_size", viewport_size)
	material.set_shader_parameter("radius", MASK_HOLE_RADIUS)
	material.set_shader_parameter("mask_color", MASK_COLOR)
	material.set_shader_parameter("hole_count", min(holes.size(), 2))
	for i in range(min(holes.size(), 2)):
		var hole := holes[i]
		material.set_shader_parameter("hole" + str(i), Vector4(hole.position.x, hole.position.y, hole.size.x, hole.size.y))
	return material


## 渲染循环点击手势，用于提示点击牌堆。
func _add_tap_hand(center: Vector2) -> void:
	var hand := _make_hand()
	hand.position = center - hand.size * 0.5
	game.add_child(hand)
	var tween := game.create_tween().bind_node(hand)
	tween.set_loops()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(hand, "scale", Vector2(0.82, 0.82), 0.22)
	tween.tween_property(hand, "scale", Vector2.ONE, 0.28)
	tween.tween_interval(0.42)


## 渲染循环拖拽手势，用于提示当前唯一允许的拖拽动作。
func _add_drag_hand(from_center: Vector2, to_center: Vector2) -> void:
	var hand := _make_hand()
	hand.position = from_center - hand.size * 0.5
	game.add_child(hand)
	var hand_ref: WeakRef = weakref(hand)
	var tween := game.create_tween().bind_node(hand)
	tween.set_loops()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(hand, "position", to_center - hand.size * 0.5, 0.72)
	tween.tween_interval(0.18)
	tween.tween_property(hand, "modulate:a", 0.0, 0.12)
	tween.tween_callback(_reset_drag_hand.bind(hand_ref, from_center))
	tween.tween_interval(0.28)


## 循环拖拽手势复位。使用 WeakRef，避免重绘释放节点后 lambda 捕获已释放对象。
func _reset_drag_hand(hand_ref: WeakRef, from_center: Vector2) -> void:
	var hand := hand_ref.get_ref() as Control
	if hand == null:
		return
	hand.position = from_center - hand.size * 0.5
	hand.modulate.a = 1.0


## 创建教学手势圆点。保持简单形状，避免引入额外贴图资源。
func _make_hand() -> Panel:
	var hand := Panel.new()
	hand.set_meta("tutorial_guidance", true)
	hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand.size = Vector2(42, 42)
	hand.z_index = 181
	hand.pivot_offset = hand.size * 0.5
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.96)
	style.border_color = game.card_border
	style.set_border_width_all(5)
	style.set_corner_radius_all(24)
	hand.add_theme_stylebox_override("panel", style)
	return hand
