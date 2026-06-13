extends Node

## EconomyManager — the "uncontrollable layer" (GAME_PLAN.md section 3.3).
##
## Publishes the current season, market prices, and demand for each
## sellable good, plus random economic events (floods, tax hikes, etc.).
## It is a PURE PUBLISHER: it talks to the rest of the game only by
## emitting EventBus signals. It does not buy, sell, or reference any
## other component. Selling lives in a later session.
##
## TIME SEAM: TimeManager does not exist yet, so for now this component
## drives itself with an internal Timer (one tick = one game-day). When
## TimeManager is built, delete the Timer and instead connect
## _advance_day() to a `day_passed` EventBus signal. That is the only
## change needed here.

# --- Tuning (safe to tweak) ---
const DAY_LENGTH_SECONDS: float = 2.0   # real seconds per game-day
const DAYS_PER_SEASON: int = 30
const GOODS: Array[String] = ["coal", "crush", "blocks"]

# Base/"fair weather" price per unit, before season/demand/drift.
const BASE_PRICES: Dictionary = {
	"coal": 50,
	"crush": 30,
	"blocks": 12,
}

const SEASONS: Array[String] = ["DRY", "RAIN", "WINTER", "SUMMER"]

# Per-season demand multiplier for each good (1.0 = normal).
# RAIN closes brick kilns and slows coal; WINTER drives coal (heating);
# DRY is prime building season.
const SEASON_DEMAND: Dictionary = {
	"DRY":    {"coal": 1.0, "crush": 1.1, "blocks": 1.2},
	"RAIN":   {"coal": 0.7, "crush": 0.8, "blocks": 0.5},
	"WINTER": {"coal": 1.4, "crush": 0.9, "blocks": 0.8},
	"SUMMER": {"coal": 0.9, "crush": 1.1, "blocks": 1.1},
}

# Random events. daily_chance is rolled each game-day per event that is
# not already active. demand_mods multiply the affected goods' demand for
# the event's duration (which flows through into price).
const EVENT_TEMPLATES: Array[Dictionary] = [
	{
		"id": "flood",
		"description": "Flood disaster — construction demand and block prices spike.",
		"daily_chance": 0.01,
		"min_days": 10, "max_days": 25,
		"demand_mods": {"blocks": 1.8, "crush": 1.5, "coal": 1.1},
	},
	{
		"id": "building_boom",
		"description": "Construction boom in the region — materials in high demand.",
		"daily_chance": 0.02,
		"min_days": 15, "max_days": 40,
		"demand_mods": {"blocks": 1.4, "crush": 1.3},
	},
	{
		"id": "recession",
		"description": "Economic downturn — material demand falls across the board.",
		"daily_chance": 0.015,
		"min_days": 20, "max_days": 50,
		"demand_mods": {"blocks": 0.6, "crush": 0.7, "coal": 0.8},
	},
	{
		"id": "fuel_shock",
		"description": "Fuel price shock — coal prices surge.",
		"daily_chance": 0.02,
		"min_days": 8, "max_days": 20,
		"demand_mods": {"coal": 1.6},
	},
	{
		"id": "tax_hike",
		"description": "Government raises duties — prices climb, demand softens.",
		"daily_chance": 0.015,
		"min_days": 30, "max_days": 60,
		"demand_mods": {"blocks": 0.85, "crush": 0.85, "coal": 0.9},
	},
]

# --- State ---
var _day: int = 0
var _season_index: int = 0

# Active events: each is {id, description, days_left, demand_mods}.
var _active_events: Array[Dictionary] = []

# Last published values, so we only emit demand changes that actually move.
var _current_demand: Dictionary = {}   # good -> float
var _current_price: Dictionary = {}    # good -> int

var _tick_timer: Timer


func _ready() -> void:
	randomize()

	# Publish the starting season and an initial economy snapshot so any
	# listener that connects at startup is in sync immediately.
	EventBus.season_changed.emit(get_current_season())
	_recompute_economy()

	# Internal day clock (see TIME SEAM note at top of file).
	_tick_timer = Timer.new()
	_tick_timer.wait_time = DAY_LENGTH_SECONDS
	_tick_timer.autostart = true
	_tick_timer.timeout.connect(_advance_day)
	add_child(_tick_timer)


# --- Public read API (query without waiting for a signal) ---

func get_current_season() -> String:
	return SEASONS[_season_index]


func get_price(good: String) -> int:
	return int(_current_price.get(good, BASE_PRICES.get(good, 0)))


func get_demand(good: String) -> float:
	return float(_current_demand.get(good, 1.0))


# --- Day / season progression ---

func _advance_day() -> void:
	_day += 1

	if _day % DAYS_PER_SEASON == 0:
		_advance_season()

	_age_active_events()
	_maybe_trigger_events()
	_recompute_economy()


func _advance_season() -> void:
	_season_index = (_season_index + 1) % SEASONS.size()
	EventBus.season_changed.emit(get_current_season())


# --- Events ---

func _is_event_active(event_id: String) -> bool:
	for ev in _active_events:
		if ev["id"] == event_id:
			return true
	return false


func _maybe_trigger_events() -> void:
	for template in EVENT_TEMPLATES:
		if _is_event_active(template["id"]):
			continue
		if randf() < float(template["daily_chance"]):
			var instance: Dictionary = {
				"id": template["id"],
				"description": template["description"],
				"days_left": randi_range(int(template["min_days"]), int(template["max_days"])),
				"demand_mods": template["demand_mods"],
			}
			_active_events.append(instance)
			EventBus.economic_event_started.emit(
				instance["id"],
				instance["description"],
				{"demand_mods": instance["demand_mods"], "days": instance["days_left"]}
			)


func _age_active_events() -> void:
	# Iterate backwards so we can remove expired events safely.
	for i in range(_active_events.size() - 1, -1, -1):
		_active_events[i]["days_left"] -= 1
		if _active_events[i]["days_left"] <= 0:
			var ended_id: String = _active_events[i]["id"]
			_active_events.remove_at(i)
			EventBus.economic_event_ended.emit(ended_id)


# --- Price / demand model ---

func _recompute_economy() -> void:
	var season_mods: Dictionary = SEASON_DEMAND[get_current_season()]

	for good in GOODS:
		# Start from the seasonal baseline, then layer active events on top.
		var demand: float = float(season_mods.get(good, 1.0))
		for ev in _active_events:
			demand *= float(ev["demand_mods"].get(good, 1.0))
		demand = clampf(demand, 0.1, 5.0)

		# Only announce demand if it meaningfully moved.
		if not _current_demand.has(good) or not is_equal_approx(_current_demand[good], demand):
			_current_demand[good] = demand
			EventBus.demand_changed.emit(good, demand)

		# Price = base * demand * small daily drift. Always re-published
		# since the drift makes it move a little each day.
		var drift: float = randf_range(0.95, 1.05)
		var price: int = maxi(1, int(round(float(BASE_PRICES[good]) * demand * drift)))
		_current_price[good] = price
		EventBus.price_changed.emit(good, price)
