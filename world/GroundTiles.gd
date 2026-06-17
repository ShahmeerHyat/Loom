extends TileMapLayer

## GroundTiles — paints the isometric ground (Graphics slice G3).
##
## PURE RENDERING (see GRAPHICS.md §0): it builds its own TileSet in code from
## the dirt sheet and fills a region with random diamond variants. It reads no
## game state and drives no component — the simulation is unaffected by it.
##
## The TileSet is built programmatically (rather than a hand-authored .tres) so
## the whole setup is reproducible from text and survives re-imports.

const GROUND_TEXTURE: String = "res://assets/tiles/ground/dirt_128x64.png"
const TILE_SIZE: Vector2i = Vector2i(128, 64)   # 2:1 dimetric diamond (GRAPHICS.md §1)
const VARIANTS: int = 8                          # full-diamond tiles in row 0 of the sheet
const RADIUS: int = 25                           # paints cells from -RADIUS..RADIUS on both axes


func _ready() -> void:
	tile_set = _build_tile_set()
	_paint_ground()


## Build an isometric TileSet whose single atlas source is row 0 of the dirt
## sheet (8 ground variants). DIAMOND_DOWN + horizontal offset is the classic
## iso layout; the iso reference grid in Grid.gd uses the matching math.
func _build_tile_set() -> TileSet:
	var ts := TileSet.new()
	ts.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	ts.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	ts.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_HORIZONTAL
	ts.tile_size = TILE_SIZE

	var atlas := TileSetAtlasSource.new()
	atlas.texture = load(GROUND_TEXTURE)
	atlas.texture_region_size = TILE_SIZE
	for i in VARIANTS:
		atlas.create_tile(Vector2i(i, 0))

	ts.add_source(atlas, 0)
	return ts


## Fill a square block of cells, picking a random ground variant per cell so the
## ground reads as natural rather than a repeating stamp.
func _paint_ground() -> void:
	randomize()
	for x in range(-RADIUS, RADIUS + 1):
		for y in range(-RADIUS, RADIUS + 1):
			set_cell(Vector2i(x, y), 0, Vector2i(randi() % VARIANTS, 0))
