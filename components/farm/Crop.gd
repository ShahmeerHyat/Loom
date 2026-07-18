extends Node

## Crop — a full sow → grow → harvest lifecycle (Mega-build: FARMING). The
## deepest day-driven component so far. Each game-day a growing crop drinks
## water (rainfed FREE in RAIN season, DOUBLE thirst in DRY), suffers a
## STRESS day when it can't drink, and matures after its growth period.
## Fertilizer raises yield (a third application BURNS it back down). Sowing
## out of season germinates poorly. A mature crop left standing too long
## rots in the field. Enough stress kills the crop outright.
##
## STANDALONE: acres / soil_fertility / irrigated are exports today — the
## wiring that reads them from an OWNED FarmLand + TerrainData is a later
## slice (the same passed-in pattern as Buyer's quality). Season is read
## live from the EconomyManager autoload (same as HUD G2).
##
## NOT AUTOPLAY beyond the clock: sow/fertilize/harvest are player calls.
## Daily growth rides TimeManager's day_passed (listen_to_clock), or manual
## advance_days() in tests. No RNG anywhere — fully deterministic.

## The crop catalogue. water_per_acre is units of the `water` resource each
## acre drinks per NORMAL day (DRY doubles it, RAIN zeroes it, irrigation
## halves it). yield_per_acre is units banked at harvest before modifiers.
const CROP_TYPES: Dictionary = {
	"wheat":     {"sow_season": "WINTER", "growth_days": 60, "water_per_acre": 2, "yield_per_acre": 40, "seeds_per_acre": 1},
	"rice":      {"sow_season": "RAIN",   "growth_days": 45, "water_per_acre": 6, "yield_per_acre": 35, "seeds_per_acre": 1},
	"cotton":    {"sow_season": "SUMMER", "growth_days": 75, "water_per_acre": 3, "yield_per_acre": 20, "seeds_per_acre": 1},
	"sugarcane": {"sow_season": "DRY",    "growth_days": 90, "water_per_acre": 5, "yield_per_acre": 80, "seeds_per_acre": 2},
}

## Sowing out of season still germinates — badly.
const OFF_SEASON_GERMINATION: float = 0.4
## Field-prep + sowing labor, cash per acre.
const SOW_COST_PER_ACRE: int = 20
## Yield boost of the 1st and 2nd fertilizer application; a 3rd+ BURNS.
const FERT_BOOSTS: Array[float] = [0.25, 0.15]
const FERT_BURN: float = 0.2
## A mature crop rots if left standing longer than this.
const SPOIL_DAYS: int = 20

enum Status { FALLOW, GROWING, MATURE, FAILED }

# --- Tuning (until FarmLand/TerrainData wiring) ---
@export var acres: float = 10.0
@export var soil_fertility: float = 0.7
@export var irrigated: bool = false
@export var listen_to_clock: bool = true

# --- State ---
var status: Status = Status.FALLOW
var crop_type: String = ""
var days_grown: int = 0
var stress_days: int = 0
var days_since_mature: int = 0
var germination: float = 1.0
var fert_applications: int = 0
var yield_multiplier: float = 1.0


func _ready() -> void:
	if listen_to_clock:
		EventBus.day_passed.connect(_on_day_passed)


# --- Player entry points ---

## Sow a crop from the catalogue. Consumes seeds + sowing cash. Sown out of
## its proper season it germinates at OFF_SEASON_GERMINATION.
func sow(type: String) -> bool:
	if status == Status.GROWING or status == Status.MATURE:
		EventBus.crop_action_failed.emit("a %s crop is already in the field" % crop_type)
		return false
	if not CROP_TYPES.has(type):
		EventBus.crop_action_failed.emit("unknown crop '%s'" % type)
		return false

	var info: Dictionary = CROP_TYPES[type]
	var seeds_needed: int = int(ceil(acres * float(info["seeds_per_acre"])))
	var sow_cost: int = int(round(acres * SOW_COST_PER_ACRE))
	if GameState.get_resource("seeds") < seeds_needed:
		EventBus.crop_action_failed.emit("need %d seeds to sow %s" % [seeds_needed, type])
		return false
	if not GameState.spend_cash(sow_cost):
		EventBus.crop_action_failed.emit("not enough cash to sow (%d)" % sow_cost)
		return false
	GameState.remove_resource("seeds", seeds_needed)

	var season_ok: bool = EconomyManager.get_current_season() == String(info["sow_season"])
	crop_type = type
	status = Status.GROWING
	days_grown = 0
	stress_days = 0
	days_since_mature = 0
	fert_applications = 0
	yield_multiplier = 1.0
	germination = 1.0 if season_ok else OFF_SEASON_GERMINATION
	EventBus.crop_sown.emit(crop_type, acres, season_ok)
	return true


## Apply fertilizer to a growing crop. 1st/2nd applications boost yield;
## a 3rd+ burns the crop back down (greed is punished).
func fertilize() -> bool:
	if status != Status.GROWING:
		EventBus.crop_action_failed.emit("no growing crop to fertilize")
		return false
	var needed: int = int(ceil(acres))
	if not GameState.remove_resource("fertilizer", needed):
		EventBus.crop_action_failed.emit("need %d fertilizer" % needed)
		return false

	fert_applications += 1
	if fert_applications <= FERT_BOOSTS.size():
		yield_multiplier += FERT_BOOSTS[fert_applications - 1]
	else:
		yield_multiplier = maxf(0.5, yield_multiplier - FERT_BURN)
	EventBus.crop_fertilized.emit(crop_type, fert_applications, yield_multiplier)
	return true


## Harvest a mature crop into inventory. Yield = acres × per-acre yield ×
## soil fertility × germination × fertilizer multiplier × stress factor.
## Returns the amount banked (0 if it couldn't).
func harvest() -> int:
	if status != Status.MATURE:
		EventBus.crop_action_failed.emit("no mature crop to harvest")
		return 0

	var info: Dictionary = CROP_TYPES[crop_type]
	var stress_factor: float = clampf(1.0 - float(stress_days) / float(info["growth_days"]), 0.25, 1.0)
	var amount: int = int(floor(acres * float(info["yield_per_acre"]) * soil_fertility \
		* germination * yield_multiplier * stress_factor))
	GameState.add_resource(crop_type, amount)
	EventBus.crop_harvested.emit(crop_type, amount)
	_clear_field()
	return amount


## Advance the crop's life by `days`. (TimeManager seam / manual for tests.)
func advance_days(days: int) -> void:
	for _i in range(days):
		_advance_one_day()


# --- Read helpers ---

func status_name() -> String:
	match status:
		Status.FALLOW: return "FALLOW"
		Status.GROWING: return "GROWING"
		Status.MATURE: return "MATURE"
		_: return "FAILED"


# --- Internal ---

func _on_day_passed(_day: int) -> void:
	advance_days(1)


func _advance_one_day() -> void:
	match status:
		Status.GROWING:
			_grow_day()
		Status.MATURE:
			days_since_mature += 1
			if days_since_mature > SPOIL_DAYS:
				status = Status.FAILED
				EventBus.crop_failed.emit(crop_type, "rotted in the field unharvested")
		_:
			pass


func _grow_day() -> void:
	var info: Dictionary = CROP_TYPES[crop_type]

	# Thirst for the day: rainfed free in RAIN, doubled in DRY drought heat,
	# halved by irrigation.
	var need: float = 0.0
	var season: String = EconomyManager.get_current_season()
	if season != "RAIN":
		need = acres * float(info["water_per_acre"])
		if season == "DRY":
			need *= 2.0
		if irrigated:
			need *= 0.5
	var need_units: int = int(ceil(need))

	if need_units > 0:
		if not GameState.remove_resource("water", need_units):
			stress_days += 1
			EventBus.crop_stressed.emit(crop_type, stress_days)

	days_grown += 1
	EventBus.crop_progressed.emit(crop_type, days_grown, int(info["growth_days"]))

	# Too many dry days kills the crop outright.
	if stress_days > int(info["growth_days"]) / 2:
		status = Status.FAILED
		EventBus.crop_failed.emit(crop_type, "died of drought stress")
		return

	if days_grown >= int(info["growth_days"]):
		status = Status.MATURE
		EventBus.crop_matured.emit(crop_type)


func _clear_field() -> void:
	status = Status.FALLOW
	crop_type = ""
	days_grown = 0
	stress_days = 0
	days_since_mature = 0
	fert_applications = 0
	yield_multiplier = 1.0
	germination = 1.0
