extends Node

## GameState — single source of truth for the player's resources.
##
## Holds cash and the tracked materials. Nothing else in the game should
## read or write these values directly with raw assignment. Instead, go
## through the methods below, which update the value AND announce the
## change on the EventBus. That way any component (UI, market, etc.) can
## react without GameState ever needing to know they exist.
##
## Session 1 scope: storage + change notifications only. No gameplay,
## no economy, no decisions live here.

# --- Starting values ---
const STARTING_CASH: int = 10000

# --- State ---
var company_name: String = ""
var cash: int = STARTING_CASH
var coal: int = 0
var limestone: int = 0
var crush: int = 0
var blocks: int = 0


func _ready() -> void:
	# Announce initial values once everything is loaded, so any listener
	# that connects at startup can sync its display immediately.
	EventBus.cash_changed.emit(cash)
	EventBus.resource_changed.emit("coal", coal)
	EventBus.resource_changed.emit("limestone", limestone)
	EventBus.resource_changed.emit("crush", crush)
	EventBus.resource_changed.emit("blocks", blocks)


# --- Company lifecycle ---

## Start a new company with the given name. Stores the name and announces
## it on the EventBus. Cash already starts at STARTING_CASH.
func start_company(name: String) -> void:
	company_name = name
	EventBus.company_started.emit(company_name)


# --- Cash ---

## Add cash (e.g. from a sale). Use a positive amount.
func add_cash(amount: int) -> void:
	if amount <= 0:
		return
	cash += amount
	EventBus.cash_changed.emit(cash)


## Try to spend cash. Returns true if the player could afford it (and the
## cash was deducted), false if not enough (nothing is deducted).
func spend_cash(amount: int) -> bool:
	if amount <= 0:
		return true
	if cash < amount:
		return false
	cash -= amount
	EventBus.cash_changed.emit(cash)
	return true


# --- Resources ---

## Returns the current amount of a tracked resource, or 0 if the name is
## not recognised.
func get_resource(resource_name: String) -> int:
	match resource_name:
		"coal": return coal
		"limestone": return limestone
		"crush": return crush
		"blocks": return blocks
		_:
			push_warning("GameState.get_resource: unknown resource '%s'" % resource_name)
			return 0


## Add to a tracked resource. Use a positive amount.
func add_resource(resource_name: String, amount: int) -> void:
	if amount <= 0:
		return
	if not _set_resource(resource_name, get_resource(resource_name) + amount):
		return
	EventBus.resource_changed.emit(resource_name, get_resource(resource_name))


## Try to remove from a tracked resource. Returns true if there was enough
## (and it was removed), false otherwise (nothing is removed).
func remove_resource(resource_name: String, amount: int) -> bool:
	if amount <= 0:
		return true
	var current: int = get_resource(resource_name)
	if current < amount:
		return false
	if not _set_resource(resource_name, current - amount):
		return false
	EventBus.resource_changed.emit(resource_name, get_resource(resource_name))
	return true


# --- Internal ---

## Writes a resource value by name. Returns false if the name is unknown.
func _set_resource(resource_name: String, value: int) -> bool:
	match resource_name:
		"coal": coal = value
		"limestone": limestone = value
		"crush": crush = value
		"blocks": blocks = value
		_:
			push_warning("GameState._set_resource: unknown resource '%s'" % resource_name)
			return false
	return true
