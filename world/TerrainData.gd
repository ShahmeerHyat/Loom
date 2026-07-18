extends Node

## TerrainData — headless elevation & terrain model for the world (Mega-build).
## The old flat world was a placeholder; this gives every grid cell an
## ELEVATION (feet), a TERRAIN TYPE (plains / hills / mountain / river) and a
## soil FERTILITY (0..1), all generated DETERMINISTICALLY from a seed via
## FastNoiseLite (same seed = same world, every run, every machine).
##
## PURE DATA PROVIDER: it mutates nothing and drives nothing. Components and
## (later) the graphics layer QUERY it — farm fertility, road slopes/transport
## cost, mine placement, iso elevation art all read from here. Wiring it into
## FarmLand / Road is a later slice (values are PASSED IN there today, the
## same pattern as Buyer's quality).

enum TerrainType { PLAINS, HILLS, MOUNTAIN, RIVER }

# --- Tuning (safe to tweak) ---
@export var width: int = 51
@export var height: int = 51
@export var noise_seed: int = 1337
## Highest peak in the world, in feet above the valley floor.
@export var max_elevation_ft: float = 3000.0
## Horizontal size of one grid cell in feet (used for slope grades).
const CELL_SIZE_FT: float = 200.0

## Normalised-elevation bands for terrain classification.
const PLAINS_BELOW: float = 0.35
const HILLS_BELOW: float = 0.65
## A cell is river where the river channel noise pinches near zero AND the
## land isn't mountain-high (rivers run through valleys, not over peaks).
const RIVER_CHANNEL_WIDTH: float = 0.06
const RIVER_MAX_ELEVATION: float = 0.55
## Rivers carve the land down — their elevation is scaled by this.
const RIVER_CARVE: float = 0.25

var _elev_noise: FastNoiseLite
var _river_noise: FastNoiseLite
var _moisture_noise: FastNoiseLite


func _ready() -> void:
	_elev_noise = FastNoiseLite.new()
	_elev_noise.seed = noise_seed
	_elev_noise.frequency = 0.05

	_river_noise = FastNoiseLite.new()
	_river_noise.seed = noise_seed + 1
	_river_noise.frequency = 0.03

	_moisture_noise = FastNoiseLite.new()
	_moisture_noise.seed = noise_seed + 2
	_moisture_noise.frequency = 0.08

	EventBus.terrain_generated.emit(width, height)


# --- Queries ---

func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height


## Elevation of a cell in feet (0 = valley floor). River cells sit low.
func elevation_at(cell: Vector2i) -> float:
	return _elevation01(cell) * max_elevation_ft


func terrain_type_at(cell: Vector2i) -> TerrainType:
	if _is_river(cell):
		return TerrainType.RIVER
	var e: float = _raw_elevation01(cell)
	if e < PLAINS_BELOW:
		return TerrainType.PLAINS
	if e < HILLS_BELOW:
		return TerrainType.HILLS
	return TerrainType.MOUNTAIN


func terrain_name_at(cell: Vector2i) -> String:
	match terrain_type_at(cell):
		TerrainType.PLAINS: return "PLAINS"
		TerrainType.HILLS: return "HILLS"
		TerrainType.MOUNTAIN: return "MOUNTAIN"
		TerrainType.RIVER: return "RIVER"
		_: return "UNKNOWN"


## Soil fertility 0..1 — what FarmLand's soil_fertility will read one day.
## Plains are the breadbasket, hills are workable, mountains are rock, and
## the river itself can't be farmed (its BANKS are plains and score high).
func fertility_at(cell: Vector2i) -> float:
	var moisture: float = _noise01(_moisture_noise, cell)
	match terrain_type_at(cell):
		TerrainType.PLAINS: return clampf(0.55 + 0.35 * moisture, 0.0, 1.0)
		TerrainType.HILLS: return clampf(0.30 + 0.25 * moisture, 0.0, 1.0)
		TerrainType.MOUNTAIN: return clampf(0.05 + 0.10 * moisture, 0.0, 1.0)
		_: return 0.0


## Grade between two cells as a fraction (0.05 = a 5% climb), computed from
## the elevation difference over the horizontal distance. Symmetric.
func slope_between(a: Vector2i, b: Vector2i) -> float:
	if a == b:
		return 0.0
	var horizontal_ft: float = a.distance_to(b) * CELL_SIZE_FT
	return absf(elevation_at(a) - elevation_at(b)) / horizontal_ft


## Haulage-time multiplier for moving FROM a cell TO a cell (≥ 1.0).
## Climbing is brutal, descending only a little slower than flat — this is
## what Road/Truck will consult when routes become spatial.
func transport_multiplier(from: Vector2i, to: Vector2i) -> float:
	var grade: float = slope_between(from, to)
	if elevation_at(to) > elevation_at(from):
		return 1.0 + grade * 8.0
	return 1.0 + grade * 2.0


# --- Internal ---

## Noise mapped from [-1, 1] into [0, 1].
func _noise01(noise: FastNoiseLite, cell: Vector2i) -> float:
	return (noise.get_noise_2d(float(cell.x), float(cell.y)) + 1.0) * 0.5


## Land elevation before river carving.
func _raw_elevation01(cell: Vector2i) -> float:
	return _noise01(_elev_noise, cell)


func _is_river(cell: Vector2i) -> bool:
	if _raw_elevation01(cell) >= RIVER_MAX_ELEVATION:
		return false
	return absf(_river_noise.get_noise_2d(float(cell.x), float(cell.y))) < RIVER_CHANNEL_WIDTH


func _elevation01(cell: Vector2i) -> float:
	var e: float = _raw_elevation01(cell)
	if _is_river(cell):
		return e * RIVER_CARVE
	return e
