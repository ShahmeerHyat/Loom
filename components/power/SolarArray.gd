extends Node

## SolarArray — photovoltaic power (Mega-build: POWER, GAME_PLAN section 24
## pulled forward). The counterweight to the Genset: a heavy one-off capex,
## then FREE power every day — but at the weather's mercy. Generation reads
## the live season (EconomyManager autoload, same as HUD G2): scorching
## SUMMER days pour power, the RAIN monsoon starves the panels.
##
## Once installed it harvests sun daily on the TimeManager heartbeat
## (listen_to_clock) — sunrise isn't a player decision; the CHOICE was the
## capex. Tests turn the clock listener off and call advance_days().
##
## Deferred (GAME_PLAN 24): panel degradation, dust/cleaning labor,
## batteries vs banked units, grid feed-in, theft.

## Season multiplier on panel output.
const SEASON_SUN: Dictionary = {
	"DRY": 1.2,
	"RAIN": 0.4,
	"WINTER": 0.7,
	"SUMMER": 1.3,
}

# --- Tuning (safe to tweak) ---
@export var price: int = 8000
## Nominal daily output in power units at multiplier 1.0.
@export var panel_kw: int = 20
@export var listen_to_clock: bool = true

# --- State ---
var installed: bool = false


func _ready() -> void:
	if listen_to_clock:
		EventBus.day_passed.connect(_on_day_passed)


## Buy and install the array (cash capex). Returns true on success.
func install() -> bool:
	if installed:
		EventBus.power_action_failed.emit("solar array is already installed")
		return false
	if not GameState.spend_cash(price):
		EventBus.power_action_failed.emit("not enough cash for solar (%d)" % price)
		return false
	installed = true
	EventBus.solar_installed.emit(price)
	return true


## Advance `days` of sunshine. (TimeManager seam / manual for tests.)
func advance_days(days: int) -> void:
	for _i in range(days):
		_generate_day()


# --- Internal ---

func _on_day_passed(_day: int) -> void:
	advance_days(1)


func _generate_day() -> void:
	if not installed:
		return
	var mult: float = float(SEASON_SUN.get(EconomyManager.get_current_season(), 1.0))
	var amount: int = int(round(panel_kw * mult))
	if amount <= 0:
		return
	GameState.add_resource("power", amount)
	EventBus.power_generated.emit("solar", amount)
