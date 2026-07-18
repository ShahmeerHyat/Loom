extends Node

## IronMine — iron-ore extraction (Mega-build: STEEL CHAIN). Same shape as
## the CoalMine: dig shift by shift down to the ore body, then produce.
## Iron sits shallower than the deep coal seam but yields the ore that
## feeds the SteelFactory — the start of the steel → weapons/construction
## branch of the economy.
##
## NOT AUTOPLAY: no timer, never advances by itself. work_shift() is the
## only entry point and the seam the labor chain plugs into later.
##
## Deferred (same list as CoalMine, GAME_PLAN 11.8): lease gating, labor
## wiring, ore body quality from ProspectSite, haulage, placement, UI.

enum State { IDLE, DIGGING, AT_SEAM }

# --- Tuning (safe to tweak) ---
## How deep the ore body sits, in feet.
@export var seam_depth: float = 800.0
## Feet dug per shift.
@export var dig_rate: float = 5.0
## Iron ore produced per shift once the ore body is reached.
@export var ore_per_shift: int = 6

# --- State ---
var current_depth: float = 0.0
var state: State = State.IDLE


## The ONE entry point. Each call = one worked shift. Before the ore body
## it digs deeper; at the ore body it produces iron ore.
func work_shift() -> void:
	if state == State.AT_SEAM:
		_produce_ore()
	else:
		_dig()


# --- Internal ---

func _dig() -> void:
	state = State.DIGGING
	current_depth = minf(current_depth + dig_rate, seam_depth)
	EventBus.iron_dig_progressed.emit(current_depth, seam_depth)

	if current_depth >= seam_depth:
		state = State.AT_SEAM
		EventBus.iron_reached_seam.emit()


func _produce_ore() -> void:
	# Interim path: ore goes straight into GameState (same documented seam
	# as the other mines — per-site stockpiles + trucking come later).
	GameState.add_resource("iron_ore", ore_per_shift)
	EventBus.iron_ore_produced.emit(ore_per_shift)


# --- Read helpers (for UI / tests) ---

func is_at_seam() -> bool:
	return state == State.AT_SEAM


func get_state_name() -> String:
	match state:
		State.IDLE: return "IDLE"
		State.DIGGING: return "DIGGING"
		State.AT_SEAM: return "AT_SEAM"
		_: return "UNKNOWN"
