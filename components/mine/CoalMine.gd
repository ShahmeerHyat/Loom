extends Node

## CoalMine — the smallest playable seed of the coal mine (GAME_PLAN.md
## sections 5 item 5, and 11). It must be DUG down to the coal seam one
## shift at a time, and only ever does something when commanded.
##
## NOT AUTOPLAY: this component has no timer and never advances by itself.
## The only thing that makes anything happen is a call to work_shift().
## Right now the player triggers that directly. In later sessions that
## single call becomes the real chain — you tell the mine manager to get
## to work, the manager finds mates, the mates' workers dig. This method
## is the seam where that chain will plug in. Nothing else changes here.
##
## Deferred to later sessions (see GAME_PLAN 11.8): lease gating, mine
## manager + mates + worker hiring, timber upkeep, rock hardness, double
## shifts, coal pockets on the way down, donkeys vs rail haulage,
## ventilation, flooding/pumps, world placement, and UI.

enum State { IDLE, DIGGING, AT_SEAM }

# --- Tuning (safe to tweak) ---
## How deep the coal seam sits, in feet (known beforehand from boring).
@export var seam_depth: float = 1200.0
## Feet dug per shift (single team; rock hardness / double shifts come later).
@export var dig_rate: float = 4.0
## Coal produced per shift once the seam is reached.
@export var coal_per_shift: int = 5

# --- State ---
var current_depth: float = 0.0
var state: State = State.IDLE


## The ONE entry point. Each call = one worked shift. Before the seam it
## digs deeper; at the seam it produces coal. Does nothing on its own.
func work_shift() -> void:
	if state == State.AT_SEAM:
		_produce_coal()
	else:
		_dig()


# --- Internal ---

func _dig() -> void:
	state = State.DIGGING
	current_depth = minf(current_depth + dig_rate, seam_depth)
	EventBus.mine_dig_progressed.emit(current_depth, seam_depth)

	if current_depth >= seam_depth:
		state = State.AT_SEAM
		EventBus.mine_reached_seam.emit()


func _produce_coal() -> void:
	# Interim path: coal goes straight into GameState (which fires
	# resource_changed). When trucks exist (Session 11) this gets routed
	# through haulage instead of landing in the global tally directly.
	GameState.add_resource("coal", coal_per_shift)
	EventBus.mine_coal_produced.emit(coal_per_shift)


# --- Read helpers (for UI / tests) ---

func is_at_seam() -> bool:
	return state == State.AT_SEAM


func get_state_name() -> String:
	match state:
		State.IDLE: return "IDLE"
		State.DIGGING: return "DIGGING"
		State.AT_SEAM: return "AT_SEAM"
		_: return "UNKNOWN"
