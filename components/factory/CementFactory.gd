extends Node

## CementFactory — a rotary kiln (Mega-build: STEEL CHAIN batch). Closes a
## long-open loop: until now cement appeared from nowhere; here limestone is
## burned with coal (kiln heat) and power into cement — feeding the
## BlockFactory and construction from our own quarry output.
##
## Kept deliberately simpler than the blast furnace (no firing/lining
## states) — the full multi-stage cement plant (crusher feed, clinker,
## gypsum blending) is a documented later slice, GAME_PLAN section 27.
##
## NOT AUTOPLAY: work_shift() is the only entry point.

# --- Tuning (safe to tweak) ---
@export var limestone_per_shift: int = 10
@export var coal_per_shift: int = 3
@export var power_per_shift: int = 4
@export var cement_per_shift: int = 6


## The ONE entry point. Each call = one kiln shift.
func work_shift() -> void:
	if GameState.get_resource("limestone") < limestone_per_shift:
		EventBus.cement_action_failed.emit("not enough limestone (%d needed)" % limestone_per_shift)
		return
	if GameState.get_resource("coal") < coal_per_shift:
		EventBus.cement_action_failed.emit("not enough coal (%d needed)" % coal_per_shift)
		return
	if GameState.get_resource("power") < power_per_shift:
		EventBus.cement_action_failed.emit("not enough power (%d needed)" % power_per_shift)
		return

	GameState.remove_resource("limestone", limestone_per_shift)
	GameState.remove_resource("coal", coal_per_shift)
	GameState.remove_resource("power", power_per_shift)
	GameState.add_resource("cement", cement_per_shift)
	EventBus.cement_produced.emit(cement_per_shift)
