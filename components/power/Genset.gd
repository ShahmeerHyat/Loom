extends Node

## Genset — a diesel generator set (Mega-build: POWER, pulling GAME_PLAN
## section 24 forward). The workhorse power source: burns FUEL per shift to
## bank POWER units that factories (steel, cement, weapons) draw down.
## Breaks down like the Crusher. Fuel comes from the FuelDepot — which
## makes the fuel_shock economic event finally bite something real.
##
## NOT AUTOPLAY: run_shift() / repair() are the entry points. The breakdown
## roll is INJECTABLE (default randf()) for deterministic tests.
##
## Deferred (GAME_PLAN 24): a live grid/load model instead of banked units,
## grid connection fees, load shedding, SOLAR co-siting, operators.

# --- Tuning (safe to tweak) ---
@export var fuel_per_shift: int = 10
@export var power_per_shift: int = 20
@export var breakdown_chance: float = 0.06
@export var repair_cost: int = 400

# --- State ---
var broken: bool = false


## One generating shift: fuel in, power banked. breakdown_roll injectable.
func run_shift(breakdown_roll: float = randf()) -> void:
	if broken:
		EventBus.power_action_failed.emit("genset is broken — repair it first")
		return
	if GameState.get_resource("fuel") < fuel_per_shift:
		EventBus.genset_no_fuel.emit()
		return

	GameState.remove_resource("fuel", fuel_per_shift)
	GameState.add_resource("power", power_per_shift)
	EventBus.power_generated.emit("genset", power_per_shift)

	if breakdown_roll < breakdown_chance:
		broken = true
		EventBus.genset_broke_down.emit()


## Repair a broken genset (cash). Returns true on success.
func repair() -> bool:
	if not broken:
		EventBus.power_action_failed.emit("genset is not broken")
		return false
	if not GameState.spend_cash(repair_cost):
		EventBus.power_action_failed.emit("not enough cash to repair (%d)" % repair_cost)
		return false
	broken = false
	EventBus.genset_repaired.emit(repair_cost)
	return true


# --- Read helpers ---

func is_broken() -> bool:
	return broken
