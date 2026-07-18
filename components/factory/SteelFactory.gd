extends Node

## SteelFactory — a blast furnace (Mega-build: STEEL CHAIN). The most
## involved processing component: the furnace must be FIRED UP with a big
## coal charge before any steel can flow, each hot shift then eats iron ore
## + coal + POWER to pour steel, the heat runs out after a few shifts
## (fire it again), and the furnace LINING slowly wears — a worn lining
## stops everything until an expensive reline.
##
## First component to CONSUME the power resource (gensets / solar supply it).
##
## NOT AUTOPLAY: fire_up() / work_shift() / reline() are the entry points.
## The lining-wear roll is INJECTABLE (default randf()) for deterministic
## tests, same pattern as LaborHazard.

enum State { COLD, HOT, RELINE_NEEDED }

# --- Tuning (safe to tweak) ---
## Coal burned to bring the furnace up to temperature.
@export var firing_coal: int = 20
## How many working shifts one firing stays hot for.
@export var heat_shifts_per_firing: int = 5
## Inputs consumed per hot shift.
@export var ore_per_shift: int = 8
@export var coal_per_shift: int = 4
@export var power_per_shift: int = 5
## Steel poured per hot shift.
@export var steel_per_shift: int = 5
## Chance per shift the lining wears out (checked after the shift).
@export var lining_wear_chance: float = 0.08
@export var reline_cost: int = 2000

# --- State ---
var state: State = State.COLD
var heat_shifts_left: int = 0


## Fire the furnace up: burns the coal charge, buys heat_shifts_per_firing
## shifts of heat. Returns true on success.
func fire_up() -> bool:
	if state == State.RELINE_NEEDED:
		EventBus.steel_action_failed.emit("furnace lining is worn — reline it first")
		return false
	if state == State.HOT:
		EventBus.steel_action_failed.emit("furnace is already hot")
		return false
	if not GameState.remove_resource("coal", firing_coal):
		EventBus.steel_action_failed.emit("need %d coal to fire the furnace" % firing_coal)
		return false
	state = State.HOT
	heat_shifts_left = heat_shifts_per_firing
	EventBus.furnace_fired.emit(heat_shifts_left)
	return true


## One hot shift: iron ore + coal + power in, steel out. The furnace cools
## when its heat runs out and the lining may wear. wear_roll is injectable.
func work_shift(wear_roll: float = randf()) -> void:
	if state == State.RELINE_NEEDED:
		EventBus.steel_action_failed.emit("furnace lining is worn — reline it first")
		return
	if state == State.COLD:
		EventBus.steel_action_failed.emit("furnace is cold — fire_up() first")
		return

	if GameState.get_resource("iron_ore") < ore_per_shift:
		EventBus.steel_action_failed.emit("not enough iron ore (%d needed)" % ore_per_shift)
		return
	if GameState.get_resource("coal") < coal_per_shift:
		EventBus.steel_action_failed.emit("not enough coal (%d needed)" % coal_per_shift)
		return
	if GameState.get_resource("power") < power_per_shift:
		EventBus.steel_action_failed.emit("not enough power (%d needed)" % power_per_shift)
		return

	GameState.remove_resource("iron_ore", ore_per_shift)
	GameState.remove_resource("coal", coal_per_shift)
	GameState.remove_resource("power", power_per_shift)
	GameState.add_resource("steel", steel_per_shift)
	EventBus.steel_produced.emit(steel_per_shift)

	# Lining wear trumps cooling — a worn furnace is down regardless.
	if wear_roll < lining_wear_chance:
		state = State.RELINE_NEEDED
		heat_shifts_left = 0
		EventBus.furnace_lining_worn.emit()
		return

	heat_shifts_left -= 1
	if heat_shifts_left <= 0:
		state = State.COLD
		EventBus.furnace_cooled.emit()


## Reline a worn furnace (cash). Leaves it COLD — fire it up again.
func reline() -> bool:
	if state != State.RELINE_NEEDED:
		EventBus.steel_action_failed.emit("lining doesn't need relining")
		return false
	if not GameState.spend_cash(reline_cost):
		EventBus.steel_action_failed.emit("not enough cash to reline (%d)" % reline_cost)
		return false
	state = State.COLD
	EventBus.furnace_relined.emit(reline_cost)
	return true


# --- Read helpers (for UI / tests) ---

func get_state_name() -> String:
	match state:
		State.COLD: return "COLD"
		State.HOT: return "HOT"
		_: return "RELINE_NEEDED"
