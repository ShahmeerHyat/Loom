extends Node

## FuelDepot — diesel supply (Mega-build: FUEL). Everything mechanical now
## drinks fuel — trucks (future rewiring), tractors, gensets — and this is
## where it comes from. The pump price DOUBLES while the economy's
## fuel_shock event is active: the depot listens to the event signals the
## same decoupled way Market caches prices (it never calls EconomyManager).
##
## NOT AUTOPLAY: buy_fuel() is the only entry point.
##
## Deferred: bulk-contract pricing, storage tanks with capacity (Warehouse
## pattern), fuel theft/pilferage, quality (adulterated diesel wrecking
## engines), the pump official wanting his envelope.

# --- Tuning (safe to tweak) ---
@export var base_price_per_litre: int = 3
@export var shock_multiplier: float = 2.0

# --- State ---
var _shock_active: bool = false


func _ready() -> void:
	EventBus.economic_event_started.connect(_on_event_started)
	EventBus.economic_event_ended.connect(_on_event_ended)


# --- Buying ---

func price_per_litre() -> int:
	if _shock_active:
		return int(round(base_price_per_litre * shock_multiplier))
	return base_price_per_litre


## Buy `litres` of diesel at the current pump price. Returns true on success.
func buy_fuel(litres: int) -> bool:
	if litres <= 0:
		EventBus.fuel_purchase_failed.emit("litres must be positive")
		return false
	var cost: int = litres * price_per_litre()
	if not GameState.spend_cash(cost):
		EventBus.fuel_purchase_failed.emit("not enough cash for %d litres (%d)" % [litres, cost])
		return false
	GameState.add_resource("fuel", litres)
	EventBus.fuel_purchased.emit(litres, cost)
	return true


# --- Internal ---

func _on_event_started(event_id: String, _description: String, _effects: Dictionary) -> void:
	if event_id == "fuel_shock":
		_shock_active = true
		EventBus.fuel_price_changed.emit(price_per_litre())


func _on_event_ended(event_id: String) -> void:
	if event_id == "fuel_shock":
		_shock_active = false
		EventBus.fuel_price_changed.emit(price_per_litre())
