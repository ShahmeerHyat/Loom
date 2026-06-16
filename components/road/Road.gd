extends Node

## Road — tiny road-condition seed (GAME_PLAN.md section 15, and 14.4).
## Models ONE steep dirt road: "the road up to the mine mouth". The road
## has a QUALITY that starts bad and changes over time:
##   - heavy truck traffic wears it down (reacts to truck_delivered, scaled
##     by load — heavier loads degrade it more),
##   - rain degrades it (moderate on the RAIN season, severe on a `flood`),
##   - a flood on a steep, low-quality road makes it IMPASSABLE — tyres slip
##     and a loaded truck can't climb, so transport naturally stops.
## It EXPOSES the effect of quality on transport (a time multiplier and a
## passable/access value) so the Truck can consult it in a LATER session.
##
## NOT AUTOPLAY: the road never advances on its own. It only REACTS to
## events the player/economy already drive (truck trips, the season tick).
## repair_road() is the single player-triggered entry point.
##
## Deferred (GAME_PLAN 15.5): the map & residential/rural zones, land
## purchase, the whole road-BUILDING material chain (subbase, aggregate
## from own crusher vs wholesaler, mixture ratios, asphalt, finishing,
## transport), road-construction contractors, multiple road segments,
## paved-vs-dirt surfaces, and actually rewiring Truck.gd to consult this.
## The flat repair_cost below is the SEAM where that sourced build/maintain
## chain plugs in. Numbers here are placeholders to balance later.

# --- Tuning (safe to tweak) ---
## Quality 0.0 (impassable dirt) .. 1.0 (pristine). Starts bad: a remote,
## dilapidated rural dirt road.
@export var quality: float = 0.25
## This road climbs to a mine mouth on an incline. Steep + dirt + heavy
## rain is what makes it un-climbable. A flat road would set this false.
@export var is_steep: bool = true

## Quality lost per ton hauled over the road (heavy trucks wear it down).
@export var wear_per_ton: float = 0.002
## Quality lost when the RAIN season arrives (normal rain — moderate).
@export var rain_wear: float = 0.05
## Quality lost when a flood hits (severe / "bad" rain).
@export var flood_wear: float = 0.15
## Below this quality, a steep road in a flood can't be climbed.
@export var climb_threshold: float = 0.5

## Flat cash cost to repair the road (placeholder for the sourced build
## chain — see the deferred note above).
@export var repair_cost: int = 5000
## Quality restored by one repair.
@export var repair_amount: float = 0.6

# --- State ---
var _is_raining: bool = false   # RAIN season active
var _is_flooding: bool = false  # flood event active (heavy rain)
var _was_passable: bool = true  # last announced passability


func _ready() -> void:
	# React to the things that already happen in the game — never self-tick.
	EventBus.truck_delivered.connect(_on_truck_delivered)
	EventBus.season_changed.connect(_on_season_changed)
	EventBus.economic_event_started.connect(_on_event_started)
	EventBus.economic_event_ended.connect(_on_event_ended)

	# Announce starting state so any listener that connects at startup syncs.
	_was_passable = is_passable()
	EventBus.road_quality_changed.emit(quality)


# --- Public read API (what the Truck will consult in a later session) ---

## Can a loaded truck use this road right now? False only when a flood
## leaves a steep, low-quality dirt road too slippery to climb. Normal rain
## alone never blocks — it just slows trips down.
func is_passable() -> bool:
	if _is_flooding and is_steep and quality < climb_threshold:
		return false
	return true


## How much longer a trip takes vs a pristine dry road. 1.0 = no penalty;
## worse quality and rain push it up (≈3x on a terrible road, more in rain).
## Only meaningful while passable.
func transport_time_multiplier() -> float:
	var m: float = 1.0 + (1.0 - quality) * 2.0
	if _is_flooding:
		m *= 2.0
	elif _is_raining:
		m *= 1.5
	return m


## A 0.0..1.0 speed/access factor (inverse of the time multiplier).
## 0.0 when impassable. Handy for scaling truck throughput later.
func access_multiplier() -> float:
	if not is_passable():
		return 0.0
	return 1.0 / transport_time_multiplier()


# --- Player-triggered maintenance ---

## Repair the road: spend repair_cost cash and raise quality. Returns true
## if it could be paid for (and was applied), false if not enough cash.
## SEAM: a later session replaces the flat cost with the sourced subbase ->
## aggregate -> mix -> asphalt -> finishing build chain.
func repair_road() -> bool:
	if not GameState.spend_cash(repair_cost):
		return false
	var before: float = quality
	_set_quality(quality + repair_amount)
	EventBus.road_repaired.emit(quality - before, repair_cost)
	return true


# --- Event reactions ---

func _on_truck_delivered(_material: String, amount: int, _cost: int) -> void:
	# Heavy loads wear the surface more.
	_set_quality(quality - float(amount) * wear_per_ton)


func _on_season_changed(season_name: String) -> void:
	_is_raining = (season_name == "RAIN")
	if _is_raining:
		_set_quality(quality - rain_wear)
	# Passability can change with weather even when quality didn't move
	# (e.g. leaving the rain), so re-check explicitly.
	_update_passability()


func _on_event_started(event_id: String, _description: String, _effects: Dictionary) -> void:
	if event_id != "flood":
		return
	_is_flooding = true
	_set_quality(quality - flood_wear)
	_update_passability()


func _on_event_ended(event_id: String) -> void:
	if event_id != "flood":
		return
	_is_flooding = false
	_update_passability()


# --- Internal ---

## Clamp + store quality, announce it, and re-check passability. Skips work
## (and the signal) when nothing actually changes.
func _set_quality(value: float) -> void:
	var clamped: float = clampf(value, 0.0, 1.0)
	if is_equal_approx(clamped, quality):
		return
	quality = clamped
	EventBus.road_quality_changed.emit(quality)
	_update_passability()


## Emit a passability signal only on the edges (passable <-> impassable).
func _update_passability() -> void:
	var now: bool = is_passable()
	if now == _was_passable:
		return
	_was_passable = now
	if now:
		EventBus.road_became_passable.emit()
	else:
		EventBus.road_became_impassable.emit(
			"flood — steep dirt road too slippery to climb"
		)
