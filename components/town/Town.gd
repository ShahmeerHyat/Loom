extends Node

## Town — tiny town-growth seed (GAME_PLAN.md section 23). You operate in a
## town that grows ORGANICALLY as you serve it: supplying it consumes goods,
## pays you cash, and grows its population; a bigger town NEEDS MORE, so demand
## rises — the demand -> sales -> revenue -> growth loop.
##
## NOT AUTOPLAY: nothing self-ticks. supply() is the player-triggered entry
## point; the demand / growth read-outs are read-only.
##
## Deferred (GAME_PLAN 23.2): better-labour-from-growth wiring (section 16);
## routing town demand into Market/Buyer; per-PERIOD satiation (each call is
## capped at current demand but no period is tracked, so repeated calls keep
## feeding growth); multiple towns/districts; services (not just goods); and
## any spatial/world map. Numbers are placeholders.

# --- The town (set per town) ---
@export var town_name: String = "Town"
@export var population: int = 1000
## Units of each good the town needs per head (demand = population * this).
@export var needs_per_capita: Dictionary = {"coal": 0.02, "crush": 0.03, "blocks": 0.05}
## Price the town pays per unit of each good.
@export var prices: Dictionary = {"coal": 50, "crush": 30, "blocks": 12}
## How much each good grows the town (construction grows it more than energy).
@export var growth_weight: Dictionary = {"coal": 1.0, "crush": 1.0, "blocks": 2.0}

# --- Tuning (safe to tweak) ---
const POP_STEP: int = 100              # population added per growth step
const GROWTH_COST_FACTOR: float = 0.1  # growth points to grow = population * this

# --- State ---
var growth_points: int = 0


# --- Read-outs ---

## Current per-period demand for a good (0 if the town doesn't use it).
## Scales with population.
func demand_for(good: String) -> int:
	if not needs_per_capita.has(good):
		return 0
	return int(round(population * float(needs_per_capita[good])))


## Growth points needed for the next population step (rises as the town grows).
func growth_threshold() -> int:
	return int(round(population * GROWTH_COST_FACTOR))


# --- Supplying the town ---

## Supply the town with `amount` of `good`. It takes up to its current demand,
## pays cash, and grows. Returns the amount accepted (0 if it couldn't).
func supply(good: String, amount: int) -> int:
	if not needs_per_capita.has(good):
		EventBus.town_supply_failed.emit("the town doesn't need '%s'" % good)
		return 0

	var accepted: int = mini(amount, demand_for(good))
	if accepted <= 0:
		EventBus.town_supply_failed.emit("the town needs no more %s right now" % good)
		return 0

	if not GameState.remove_resource(good, accepted):
		EventBus.town_supply_failed.emit("not enough %s to supply" % good)
		return 0

	var revenue: int = accepted * int(prices.get(good, 0))
	GameState.add_cash(revenue)

	var gained: int = int(round(accepted * float(growth_weight.get(good, 1.0))))
	growth_points += gained
	EventBus.town_supplied.emit(good, accepted, revenue, gained)

	_check_growth()
	return accepted


# --- Internal ---

func _check_growth() -> void:
	var t: int = growth_threshold()
	while t > 0 and growth_points >= t:
		growth_points -= t
		population += POP_STEP
		EventBus.town_grew.emit(population)
		t = growth_threshold()
