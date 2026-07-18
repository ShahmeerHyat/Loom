extends Node

## Warehouse — per-site storage (Mega-build: STORAGE). The first concrete
## step on the long-documented "interim path" seam: today every mine and
## factory deposits straight into the global GameState tally; the real
## model is production → SITE STOCKPILE → trucking → market. This component
## is that stockpile: a capacity-capped store you deposit into and withdraw
## from. Rerouting the producers through it is the later wiring slice.
##
## NOT AUTOPLAY: deposit() / withdraw() are the only entry points.
##
## Deferred: per-material bins, spoilage (crops rot in a leaky godown),
## theft/watchmen (LaborCrew wiring), producer rerouting, spatial placement.

# --- Tuning (safe to tweak) ---
@export var warehouse_name: String = "Site Store"
## Total units of everything it can hold.
@export var capacity: int = 500

# --- State ---
## material -> units stored here.
var stock: Dictionary = {}


# --- Moving material ---

## Move up to `amount` of a material from inventory into storage. Accepts
## what fits and what exists. Returns the amount actually stored.
func deposit(material: String, amount: int) -> int:
	if amount <= 0:
		EventBus.warehouse_action_failed.emit("amount must be positive")
		return 0
	var space: int = capacity - stored_total()
	if space <= 0:
		EventBus.warehouse_action_failed.emit("%s is full" % warehouse_name)
		return 0

	var accept: int = mini(amount, space)
	accept = mini(accept, GameState.get_resource(material))
	if accept <= 0:
		EventBus.warehouse_action_failed.emit("no %s in inventory to store" % material)
		return 0

	GameState.remove_resource(material, accept)
	stock[material] = int(stock.get(material, 0)) + accept
	EventBus.warehouse_stored.emit(material, accept, stored_total(), capacity)
	return accept


## Move up to `amount` of a material from storage back to inventory.
## Returns the amount actually withdrawn.
func withdraw(material: String, amount: int) -> int:
	if amount <= 0:
		EventBus.warehouse_action_failed.emit("amount must be positive")
		return 0
	var have: int = int(stock.get(material, 0))
	var take: int = mini(amount, have)
	if take <= 0:
		EventBus.warehouse_action_failed.emit("no %s stored in %s" % [material, warehouse_name])
		return 0

	stock[material] = have - take
	if stock[material] <= 0:
		stock.erase(material)
	GameState.add_resource(material, take)
	EventBus.warehouse_withdrawn.emit(material, take)
	return take


# --- Read helpers ---

func stored_total() -> int:
	var total: int = 0
	for material in stock:
		total += int(stock[material])
	return total


func space_left() -> int:
	return capacity - stored_total()


func stored_of(material: String) -> int:
	return int(stock.get(material, 0))
