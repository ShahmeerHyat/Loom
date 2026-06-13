extends Node

## Crusher — tiny single-stage crusher (GAME_PLAN.md section 5 item 8, and
## section 13). Consumes raw limestone and produces crush, with a
## breakdown / repair mechanic. This is the first component that CONSUMES
## one resource to make another — the first real link in the chain.
##
## NOT AUTOPLAY: no timer, never runs by itself. work_shift() is the only
## entry point and the seam where the future operator/labor chain plugs in.
##
## Deferred (GAME_PLAN 13.8): the jaw -> impact multi-stage chain,
## conveyors, grizzly screening & aggregate grades (Session 9), the
## excavator, generators / power & electricity, operators / labor, the
## shed, repair cost / parts, trucks / loading, placement, UI.

enum State { OPERATIONAL, BROKEN }

# --- Tuning (safe to tweak) ---
## Raw limestone consumed per shift.
@export var limestone_per_shift: int = 10
## Crush produced per shift (1:1 for now; dust / grade split is Session 9).
@export var crush_per_shift: int = 10
## Chance (0..1) the machine breaks down after a worked shift.
@export var breakdown_chance: float = 0.1

# --- State ---
var state: State = State.OPERATIONAL


## The ONE entry point. Each call = one worked shift. Needs enough raw
## limestone to feed it; may break down from wear afterwards.
func work_shift() -> void:
	if state == State.BROKEN:
		return  # down until repair()

	if GameState.get_resource("limestone") < limestone_per_shift:
		EventBus.crusher_no_input.emit()
		return

	GameState.remove_resource("limestone", limestone_per_shift)
	GameState.add_resource("crush", crush_per_shift)
	EventBus.crush_produced.emit(crush_per_shift)

	# Wear: a worked shift may break the machine.
	if randf() < breakdown_chance:
		state = State.BROKEN
		EventBus.crusher_broke_down.emit()


## Repair a broken crusher and put it back in operation.
func repair() -> void:
	if state == State.BROKEN:
		state = State.OPERATIONAL
		EventBus.crusher_repaired.emit()


# --- Read helpers (for UI / tests) ---

func is_broken() -> bool:
	return state == State.BROKEN


func get_state_name() -> String:
	match state:
		State.OPERATIONAL: return "OPERATIONAL"
		State.BROKEN: return "BROKEN"
		_: return "UNKNOWN"
