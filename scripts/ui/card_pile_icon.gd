class_name CardPileIcon
extends Control

@export_enum("draw", "discard") var pile_kind: String = "draw":
	set(value):
		pile_kind = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var card_size := Vector2(minf(size.x * 0.58, 76.0), minf(size.y * 0.68, 96.0))
	var base := Vector2((size.x - card_size.x) * 0.5 - 8.0, (size.y - card_size.y) * 0.5 + 6.0)
	var offsets := [Vector2(0, 0), Vector2(7, -6), Vector2(14, -12)]
	if pile_kind == "discard":
		offsets = [Vector2(0, -10), Vector2(8, -3), Vector2(15, 5)]

	draw_circle(size * 0.5 + Vector2(6, -4), minf(size.x, size.y) * 0.38, Color(0.04, 0.71, 0.88, 0.09))
	for index in offsets.size():
		var alpha := 0.55 + index * 0.18
		_draw_card_back(base + offsets[index], card_size, alpha)

	var arrow_start := Vector2(size.x * 0.30, size.y * 0.70)
	var arrow_end := Vector2(size.x * 0.68, size.y * 0.34)
	if pile_kind == "discard":
		arrow_start = Vector2(size.x * 0.30, size.y * 0.33)
		arrow_end = Vector2(size.x * 0.68, size.y * 0.71)
	_draw_arrow(arrow_start, arrow_end)


func _draw_card_back(position: Vector2, card_size: Vector2, alpha: float) -> void:
	var cut := minf(card_size.x, card_size.y) * 0.11
	var points := PackedVector2Array([
		position + Vector2(cut, 0),
		position + Vector2(card_size.x - cut, 0),
		position + Vector2(card_size.x, cut),
		position + Vector2(card_size.x, card_size.y - cut),
		position + Vector2(card_size.x - cut, card_size.y),
		position + Vector2(cut, card_size.y),
		position + Vector2(0, card_size.y - cut),
		position + Vector2(0, cut),
	])
	var fill := Color(0.025, 0.13, 0.20, alpha)
	var outline := Color(0.74, 0.43, 0.20, alpha)
	draw_colored_polygon(points, fill)
	for point_index in points.size():
		draw_line(points[point_index], points[(point_index + 1) % points.size()], outline, 2.0, true)

	var center := position + card_size * 0.5
	draw_arc(center, card_size.x * 0.18, 0.2, TAU - 0.2, 20, Color(0.15, 0.78, 0.93, alpha * 0.8), 1.5, true)
	draw_circle(center, card_size.x * 0.045, Color(0.84, 0.65, 0.30, alpha))


func _draw_arrow(start: Vector2, finish: Vector2) -> void:
	var glow := Color(0.12, 0.86, 0.95, 0.22)
	var color := Color(0.85, 0.66, 0.31, 0.95)
	draw_line(start, finish, glow, 7.0, true)
	draw_line(start, finish, color, 2.5, true)
	var direction := (finish - start).normalized()
	var normal := Vector2(-direction.y, direction.x)
	var arrow_base := finish - direction * 11.0
	draw_line(finish, arrow_base + normal * 7.0, color, 2.5, true)
	draw_line(finish, arrow_base - normal * 7.0, color, 2.5, true)
