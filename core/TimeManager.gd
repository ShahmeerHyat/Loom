extends Node

## TimeManager — the single game clock (Mega-build). This is the TIME SEAM
## every earlier component left open, finally filled: one tick = one
## game-day, announced to the whole game as EventBus.day_passed(day).
## EconomyManager's old internal Timer is gone — it listens here now, and
## every day-based component (crops, loans, rent, contract/lease deadlines)
## connects to the same heartbeat.
##
## AUTOPLAY EXCEPTION: like the old EconomyManager timer this is the ONE
## self-ticking node in the game. Everything else still only moves when
## told. stop_clock() / start_clock() pause the world (tests stop the clock
## and drive advance_days() by hand so every check is deterministic).

# --- Tuning (safe to tweak) ---
const DAY_LENGTH_SECONDS: float = 2.0   # real seconds per game-day

# --- State ---
var current_day: int = 0

var _timer: Timer


func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = DAY_LENGTH_SECONDS
	_timer.autostart = true
	_timer.timeout.connect(_on_tick)
	add_child(_timer)


## Advance the world clock by `days`, emitting day_passed once per day so
## every listener sees each day individually (interest compounds daily,
## crops grow daily, deadlines count daily).
func advance_days(days: int) -> void:
	for _i in range(days):
		current_day += 1
		EventBus.day_passed.emit(current_day)


## Pause the self-ticking clock. The world stands still; advance_days()
## still works — that's how tests fast-forward deterministically.
func stop_clock() -> void:
	_timer.stop()


## Resume the self-ticking clock.
func start_clock() -> void:
	_timer.start()


func is_running() -> bool:
	return not _timer.is_stopped()


# --- Internal ---

func _on_tick() -> void:
	advance_days(1)
