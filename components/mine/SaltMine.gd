extends Node

## SaltMine — smallest playable seed of a salt mine (GAME_PLAN.md section
## 5 item 7, and section 12). Mirrors CoalMine / LimestoneQuarry's manual,
## no-autoplay pattern, with salt's twist: a gypsum overburden to strip,
## then a salt seam, plus a cutting-vs-explosives extraction choice that
## (for now) changes ONLY output per shift.
##
## NOT AUTOPLAY: no timer, never advances by itself. work_shift() is the
## only entry point and the seam where the future mine-manager -> mates ->
## workers chain will plug in.
##
## Salt geology / methods here come from secondhand domain knowledge; some
## details are UNVERIFIED (see GAME_PLAN section 12).
##
## Deferred (per GAME_PLAN 12.6): donkeys/haulage (salt uses carts/trucks
## anyway), processing plant (washing/grinding/packaging), lease, mates
## hiring, danger/accident & blasting risk, transport, placement, UI.

enum State { IDLE, STRIPPING, EXTRACTING }
enum ExtractionMethod { CUTTING_MACHINE, EXPLOSIVES }

# --- Tuning (safe to tweak) ---
## Depth of gypsum overburden to strip before the salt seam is exposed (ft).
@export var overburden_depth: float = 40.0
## Feet of overburden stripped per shift.
@export var strip_rate: float = 5.0
## How salt is extracted. Cutting machine = slower/safer; explosives =
## higher output/more dangerous (danger mechanic deferred — output only).
@export var extraction_method: ExtractionMethod = ExtractionMethod.CUTTING_MACHINE
## Salt produced per shift with a cutting machine (the lower output).
@export var cutting_output_per_shift: int = 6
## Salt produced per shift with explosives / blasting (the higher output).
@export var explosives_output_per_shift: int = 14

# --- State ---
var current_overburden: float = 0.0
var state: State = State.IDLE


## The ONE entry point. Each call = one worked shift. While stripping it
## clears gypsum overburden; once the salt seam is exposed it produces salt.
func work_shift() -> void:
	if state == State.EXTRACTING:
		_extract()
	else:
		_strip()


## Switch the extraction method (cutting machine vs explosives).
func set_extraction_method(method: ExtractionMethod) -> void:
	extraction_method = method


## Salt produced per shift for the currently selected method.
func current_output_per_shift() -> int:
	match extraction_method:
		ExtractionMethod.EXPLOSIVES: return explosives_output_per_shift
		_: return cutting_output_per_shift


# --- Internal ---

func _strip() -> void:
	state = State.STRIPPING
	current_overburden = minf(current_overburden + strip_rate, overburden_depth)
	EventBus.salt_strip_progressed.emit(current_overburden, overburden_depth)

	if current_overburden >= overburden_depth:
		state = State.EXTRACTING
		EventBus.salt_reached_seam.emit()


func _extract() -> void:
	# Interim path: salt goes straight into GameState. Haulage (carts /
	# trucks) reroutes this in a later session.
	var amount: int = current_output_per_shift()
	GameState.add_resource("salt", amount)
	EventBus.salt_produced.emit(amount)


# --- Read helpers (for UI / tests) ---

func is_extracting() -> bool:
	return state == State.EXTRACTING


func get_state_name() -> String:
	match state:
		State.IDLE: return "IDLE"
		State.STRIPPING: return "STRIPPING"
		State.EXTRACTING: return "EXTRACTING"
		_: return "UNKNOWN"


func get_method_name() -> String:
	match extraction_method:
		ExtractionMethod.CUTTING_MACHINE: return "CUTTING_MACHINE"
		ExtractionMethod.EXPLOSIVES: return "EXPLOSIVES"
		_: return "UNKNOWN"
