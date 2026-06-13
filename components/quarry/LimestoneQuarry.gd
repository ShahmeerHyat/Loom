extends Node

## LimestoneQuarry — the smallest playable seed of a surface limestone
## quarry (GAME_PLAN.md section 5 item 6). Mirrors CoalMine's pattern
## (manual, no-autoplay, work_shift()-driven) with a DIFFERENT output.
##
## A coal mine digs deep to a seam; a quarry is open-pit. First you strip
## the overburden (loose topsoil/rock on top), then you extract raw
## limestone. So the shape mirrors the mine: IDLE -> STRIPPING ->
## EXTRACTING, in place of IDLE -> DIGGING -> AT_SEAM.
##
## NOT AUTOPLAY: no timer, never advances by itself. The only thing that
## makes anything happen is a call to work_shift() — the seam where the
## future mine-manager -> mates -> workers command chain will plug in.
##
## Output is RAW limestone (a new GameState resource). The crusher
## (Session 8) and grizzly (Session 9) later turn it into crush.
##
## Deferred (see GAME_PLAN 11.8 / future sessions): crusher + grizzly +
## conveyors, lease gating, manager/labor hiring, trucks, reserve limits,
## equipment, world placement, and UI.

enum State { IDLE, STRIPPING, EXTRACTING }

# --- Tuning (safe to tweak) ---
## Depth of overburden to strip before workable limestone is exposed (ft).
@export var overburden_depth: float = 30.0
## Feet of overburden stripped per shift.
@export var strip_rate: float = 5.0
## Raw limestone produced per shift once extracting.
@export var limestone_per_shift: int = 8

# --- State ---
var current_overburden: float = 0.0
var state: State = State.IDLE


## The ONE entry point. Each call = one worked shift. While stripping it
## clears overburden; once exposed it produces raw limestone. Does nothing
## on its own.
func work_shift() -> void:
	if state == State.EXTRACTING:
		_extract()
	else:
		_strip()


# --- Internal ---

func _strip() -> void:
	state = State.STRIPPING
	current_overburden = minf(current_overburden + strip_rate, overburden_depth)
	EventBus.quarry_strip_progressed.emit(current_overburden, overburden_depth)

	if current_overburden >= overburden_depth:
		state = State.EXTRACTING
		EventBus.quarry_reached_limestone.emit()


func _extract() -> void:
	# Interim path: raw limestone goes straight into GameState. When trucks
	# exist (Session 11) this gets routed through haulage instead.
	GameState.add_resource("limestone", limestone_per_shift)
	EventBus.quarry_limestone_produced.emit(limestone_per_shift)


# --- Read helpers (for UI / tests) ---

func is_extracting() -> bool:
	return state == State.EXTRACTING


func get_state_name() -> String:
	match state:
		State.IDLE: return "IDLE"
		State.STRIPPING: return "STRIPPING"
		State.EXTRACTING: return "EXTRACTING"
		_: return "UNKNOWN"
