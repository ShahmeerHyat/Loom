extends Node2D

## Grid — isometric reference grid (rebuilt for the iso pivot, slice G3).
##
## Pure presentation: no game logic, talks to no other component. Draws a faint
## diamond lattice using the SAME iso math as the ground TileMapLayer (centre of
## cell (x,y) = ((x-y)*w/2, (x+y)*h/2)), so the lines sit exactly on the tiles
## and give a visible sense of cell scale. snap_to_grid() maps a world point to
## its iso cell centre, for future placement components.

@export var tile_size: Vector2i = Vector2i(128, 64)
@export var radius: int = 25
@export var line_color: Color = Color(1, 1, 1, 0.06)
@export var axis_color: Color = Color(1, 1, 1, 0.14)


func _draw() -> void:
	# Outline each cell as a diamond. Shared edges overlap (drawn twice); at this
	# low alpha that's an acceptable, barely-visible seam for a reference grid.
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var color: Color = axis_color if (x == 0 or y == 0) else line_color
			_draw_diamond(_cell_center(x, y), color)


## World-space centre of iso cell (x, y) — matches DIAMOND_DOWN tile placement.
func _cell_center(x: int, y: int) -> Vector2:
	return Vector2((x - y) * tile_size.x / 2.0, (x + y) * tile_size.y / 2.0)


func _draw_diamond(center: Vector2, color: Color) -> void:
	var hw: float = tile_size.x / 2.0
	var hh: float = tile_size.y / 2.0
	var top: Vector2 = center + Vector2(0, -hh)
	var right: Vector2 = center + Vector2(hw, 0)
	var bottom: Vector2 = center + Vector2(0, hh)
	var left: Vector2 = center + Vector2(-hw, 0)
	draw_line(top, right, color, 1.0)
	draw_line(right, bottom, color, 1.0)
	draw_line(bottom, left, color, 1.0)
	draw_line(left, top, color, 1.0)


## Snap a world-space position to the centre of the iso cell it falls in.
## (Inverse of _cell_center.)
func snap_to_grid(world_pos: Vector2) -> Vector2:
	var hw: float = tile_size.x / 2.0
	var hh: float = tile_size.y / 2.0
	var cx: int = roundi((world_pos.x / hw + world_pos.y / hh) / 2.0)
	var cy: int = roundi((world_pos.y / hh - world_pos.x / hw) / 2.0)
	return _cell_center(cx, cy)
