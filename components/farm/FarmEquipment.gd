extends Node

## FarmEquipment — a farm machine (Mega-build: FARMING). A tractor,
## harvester or thresher: bought with cash, burns FUEL per task, multiplies
## farm work, and can break down like the Crusher.
##
## STANDALONE: work_multiplier is the future throughput driver — a later
## slice makes a harvester cut a mature Crop in one day instead of hand
## labor, exactly like LaborCrew.productive_capacity() will drive mines.
## For now run_task() proves the own → fuel → work → wear loop.
##
## NOT AUTOPLAY: purchase() / run_task() / repair() are the entry points.
## The breakdown roll is INJECTABLE (default randf()) — deterministic tests.

enum Kind { TRACTOR, HARVESTER, THRESHER }

# --- Tuning (safe to tweak) ---
@export var equipment_name: String = "Tractor 240"
@export var kind: Kind = Kind.TRACTOR
@export var price: int = 3000
## Litres of fuel one task burns.
@export var fuel_per_task: int = 10
## How many hands' worth of work one task does (future Crop/harvest wiring).
@export var work_multiplier: float = 3.0
@export var breakdown_chance: float = 0.08
@export var repair_cost: int = 300

# --- State ---
var owned: bool = false
var broken: bool = false


## Buy the machine. Returns true on success.
func purchase() -> bool:
	if owned:
		EventBus.equipment_action_failed.emit("%s is already owned" % equipment_name)
		return false
	if not GameState.spend_cash(price):
		EventBus.equipment_action_failed.emit("not enough cash for %s (%d)" % [equipment_name, price])
		return false
	owned = true
	EventBus.equipment_purchased.emit(equipment_name, kind_name(), price)
	return true


## Work one task: burns fuel, may break down afterwards. breakdown_roll is
## injectable for deterministic tests. Returns true if the task ran.
func run_task(breakdown_roll: float = randf()) -> bool:
	if not owned:
		EventBus.equipment_action_failed.emit("%s is not owned yet" % equipment_name)
		return false
	if broken:
		EventBus.equipment_action_failed.emit("%s is broken — repair it first" % equipment_name)
		return false
	if not GameState.remove_resource("fuel", fuel_per_task):
		EventBus.equipment_action_failed.emit("not enough fuel (%d litres)" % fuel_per_task)
		return false

	EventBus.equipment_worked.emit(equipment_name, fuel_per_task)

	if breakdown_roll < breakdown_chance:
		broken = true
		EventBus.equipment_broke_down.emit(equipment_name)
	return true


## Repair a broken machine (cash). Returns true on success.
func repair() -> bool:
	if not broken:
		EventBus.equipment_action_failed.emit("%s is not broken" % equipment_name)
		return false
	if not GameState.spend_cash(repair_cost):
		EventBus.equipment_action_failed.emit("not enough cash to repair (%d)" % repair_cost)
		return false
	broken = false
	EventBus.equipment_repaired.emit(equipment_name, repair_cost)
	return true


# --- Read helpers ---

func kind_name() -> String:
	match kind:
		Kind.TRACTOR: return "TRACTOR"
		Kind.HARVESTER: return "HARVESTER"
		_: return "THRESHER"
