extends Node2D

## Grid — draws a top-down reference grid for the game world.
##
## Pure presentation: no game logic, talks to no other component. It just
## renders a grid centred on the origin so the world has a visible sense
## of scale and placement. cell_size is exported so future placement
## components can read it / snap to it via snap_to_grid().

@export var cell_size: int = 64
@export var cells_x: int = 50
@export var cells_y: int = 50
@export var background_color: Color = Color(0.12, 0.12, 0.14)
@export var line_color: Color = Color(1, 1, 1, 0.08)
@export var axis_color: Color = Color(1, 1, 1, 0.18)


func _draw() -> void:
	var half_w: int = cells_x * cell_size / 2
	var half_h: int = cells_y * cell_size / 2

	# Ground fill behind the lines so the grid reads against any clear colour.
	draw_rect(
		Rect2(-half_w, -half_h, cells_x * cell_size, cells_y * cell_size),
		background_color,
		true
	)

	# Vertical lines (the centre line uses the brighter axis colour).
	for i in range(-cells_x / 2, cells_x / 2 + 1):
		var x: int = i * cell_size
		draw_line(Vector2(x, -half_h), Vector2(x, half_h), axis_color if i == 0 else line_color, 1.0)

	# Horizontal lines.
	for j in range(-cells_y / 2, cells_y / 2 + 1):
		var y: int = j * cell_size
		draw_line(Vector2(-half_w, y), Vector2(half_w, y), axis_color if j == 0 else line_color, 1.0)


## Snap a world-space position to the bottom-left corner of its grid cell.
func snap_to_grid(world_pos: Vector2) -> Vector2:
	return (world_pos / float(cell_size)).floor() * float(cell_size)
