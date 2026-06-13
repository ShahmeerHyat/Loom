extends Node

## Truck — tiny haulage seed (GAME_PLAN.md section 5 item 11, and section
## 14). Models capacity + per-trip cost. Each trip loads up to capacity of
## a material from a (for now abstract) field source and delivers it into
## GameState inventory, charging cost_per_trip in cash. Bigger trucks cost
## less per unit hauled — the economies of scale from section 14.2.
##
## This is the first component to SPEND CASH in gameplay.
##
## NOT AUTOPLAY: no timer, never runs by itself. run_trip() is the only
## entry point and the seam where dispatch / routing will plug in later.
##
## Deferred (GAME_PLAN 14.7): owned-vs-hired cost models, weighbridges,
## road quality & rain-blocked access, royalty / tax slips, buyers &
## payment terms, trucks-as-revenue, and per-site stockpiles (mines still
## deposit directly into GameState today; a later session reroutes them
## through site piles that trucks haul from). Costs here are placeholders
## to be calibrated against the economy later.

# --- Tuning (safe to tweak) ---
## Units (e.g. tons) the truck can carry in one trip.
@export var capacity: int = 20
## Cash charged per trip (fuel + driver / service charges). Flat per trip,
## regardless of how full the load is.
@export var cost_per_trip: int = 8000


## Run one haulage trip: load min(capacity, available) of `material` from
## the source and deliver it into GameState, charging cost_per_trip in cash.
## Returns the amount delivered (0 if the trip couldn't run).
func run_trip(material: String, available: int) -> int:
	if available <= 0:
		EventBus.truck_trip_failed.emit("nothing to haul")
		return 0

	if not GameState.spend_cash(cost_per_trip):
		EventBus.truck_trip_failed.emit("not enough cash for trip cost")
		return 0

	var loaded: int = mini(capacity, available)
	GameState.add_resource(material, loaded)
	EventBus.truck_delivered.emit(material, loaded, cost_per_trip)
	return loaded


# --- Read helpers (for UI / tests) ---

## Cash cost per unit actually delivered, given how much is at the source.
## Handy for comparing truck sizes. Returns 0.0 if nothing would load.
func cost_per_unit(available: int) -> float:
	var loaded: int = mini(capacity, maxi(0, available))
	if loaded <= 0:
		return 0.0
	return float(cost_per_trip) / float(loaded)
