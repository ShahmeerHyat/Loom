extends Node

## ApartmentBuilding — property development (Mega-build: PROPERTY, GAME_PLAN
## section 25 pulled forward). Loom is NOT just a mining game: pour our own
## blocks, cement and steel into a building shift by shift, and when it
## tops out it becomes the game's first PASSIVE INCOME — rent accrues every
## day on the TimeManager heartbeat, collected when the player calls.
## Occupancy starts half-full and climbs as rent is collected (word gets
## around a well-run building).
##
## NOT AUTOPLAY beyond the clock: build_shift() / collect_rent() are player
## calls; daily rent accrual rides day_passed (listen_to_clock).
##
## Deferred (GAME_PLAN 25): land purchase gating (FarmLand pattern),
## multiple unit sizes, tenants with needs (Town wiring), maintenance decay,
## property value & resale, mortgages via the Bank.

enum Status { PLANNED, UNDER_CONSTRUCTION, COMPLETE }

# --- Tuning (safe to tweak) ---
@export var building_name: String = "Canal View Apartments"
## Materials + labor cash one construction shift consumes.
@export var blocks_per_shift: int = 20
@export var cement_per_shift: int = 5
@export var steel_per_shift: int = 2
@export var labor_cost_per_shift: int = 100
## Progress one shift adds, and the total needed to top out.
@export var points_per_shift: int = 20
@export var points_required: int = 100
## Rent per day at 100% occupancy.
@export var rent_per_day: int = 50
@export var listen_to_clock: bool = true

# --- State ---
var status: Status = Status.PLANNED
var points: int = 0
var occupancy: float = 0.5
var accrued_rent: int = 0


func _ready() -> void:
	if listen_to_clock:
		EventBus.day_passed.connect(_on_day_passed)


# --- Construction ---

## One construction shift: materials + labor cash in, progress out.
func build_shift() -> void:
	if status == Status.COMPLETE:
		EventBus.property_action_failed.emit("%s is already complete" % building_name)
		return
	if GameState.get_resource("blocks") < blocks_per_shift:
		EventBus.property_action_failed.emit("not enough blocks (%d needed)" % blocks_per_shift)
		return
	if GameState.get_resource("cement") < cement_per_shift:
		EventBus.property_action_failed.emit("not enough cement (%d needed)" % cement_per_shift)
		return
	if GameState.get_resource("steel") < steel_per_shift:
		EventBus.property_action_failed.emit("not enough steel (%d needed)" % steel_per_shift)
		return
	if not GameState.spend_cash(labor_cost_per_shift):
		EventBus.property_action_failed.emit("not enough cash for labor (%d)" % labor_cost_per_shift)
		return

	GameState.remove_resource("blocks", blocks_per_shift)
	GameState.remove_resource("cement", cement_per_shift)
	GameState.remove_resource("steel", steel_per_shift)

	status = Status.UNDER_CONSTRUCTION
	points += points_per_shift
	EventBus.construction_progressed.emit(building_name, points, points_required)

	if points >= points_required:
		status = Status.COMPLETE
		EventBus.building_completed.emit(building_name)


# --- Rent ---

## Collect everything accrued into cash. Each collection nudges occupancy
## up (capped full). Returns the amount collected.
func collect_rent() -> int:
	if accrued_rent <= 0:
		EventBus.property_action_failed.emit("no rent accrued to collect")
		return 0
	var amount: int = accrued_rent
	accrued_rent = 0
	GameState.add_cash(amount)
	occupancy = minf(1.0, occupancy + 0.1)
	EventBus.rent_collected.emit(building_name, amount)
	return amount


## Advance `days` of the building's life. (TimeManager seam / tests.)
func advance_days(days: int) -> void:
	for _i in range(days):
		_accrue_day()


# --- Read helpers ---

func status_name() -> String:
	match status:
		Status.PLANNED: return "PLANNED"
		Status.UNDER_CONSTRUCTION: return "UNDER_CONSTRUCTION"
		_: return "COMPLETE"


# --- Internal ---

func _on_day_passed(_day: int) -> void:
	advance_days(1)


func _accrue_day() -> void:
	if status != Status.COMPLETE:
		return
	var amount: int = int(rent_per_day * occupancy)
	if amount <= 0:
		return
	accrued_rent += amount
	EventBus.rent_accrued.emit(building_name, amount)
