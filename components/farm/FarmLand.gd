extends Node

## FarmLand — an agricultural parcel (Mega-build: FARMING). Loom is not just
## a mining game (GAME_PLAN section 25 spirit): buy farm land, irrigate it,
## and grow crops on it (Crop.gd) worked by machines (FarmEquipment.gd).
##
## STANDALONE: soil_fertility is an export today — the wiring that reads it
## from TerrainData.fertility_at(the parcel's cell) is a later slice (the
## same passed-in pattern as Buyer's quality). Likewise a Crop doesn't yet
## check that a parcel is OWNED — that gate is future wiring.
##
## NOT AUTOPLAY: purchase() / install_irrigation() are the only entry points.

enum Status { AVAILABLE, OWNED }

# --- The parcel on offer ---
@export var parcel_name: String = "River Field"
@export var acres: float = 10.0
@export var price_per_acre: int = 200
## Soil fertility 0..1 (later read from TerrainData at the parcel's cell).
@export var soil_fertility: float = 0.7
## Cost of sinking a tubewell / cutting a canal feeder to the parcel.
@export var irrigation_cost: int = 1500

# --- State ---
var status: Status = Status.AVAILABLE
var irrigated: bool = false


## Buy the parcel outright (cash). Returns true on success.
func purchase() -> bool:
	if status == Status.OWNED:
		EventBus.farm_action_failed.emit("%s is already owned" % parcel_name)
		return false
	var cost: int = int(round(acres * price_per_acre))
	if not GameState.spend_cash(cost):
		EventBus.farm_action_failed.emit("not enough cash to buy %s (%d)" % [parcel_name, cost])
		return false
	status = Status.OWNED
	EventBus.farm_land_purchased.emit(parcel_name, acres, cost)
	return true


## Install irrigation on an owned parcel (halves a crop's thirst — Crop.gd
## reads its own `irrigated` export until parcel wiring lands).
func install_irrigation() -> bool:
	if status != Status.OWNED:
		EventBus.farm_action_failed.emit("buy %s before irrigating it" % parcel_name)
		return false
	if irrigated:
		EventBus.farm_action_failed.emit("%s is already irrigated" % parcel_name)
		return false
	if not GameState.spend_cash(irrigation_cost):
		EventBus.farm_action_failed.emit("not enough cash for irrigation (%d)" % irrigation_cost)
		return false
	irrigated = true
	EventBus.farm_irrigation_installed.emit(parcel_name, irrigation_cost)
	return true


# --- Read helpers ---

func is_owned() -> bool:
	return status == Status.OWNED


func status_name() -> String:
	match status:
		Status.AVAILABLE: return "AVAILABLE"
		_: return "OWNED"
