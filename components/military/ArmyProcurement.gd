extends Node

## ArmyProcurement — an army supply tender (Mega-build: MILITARY). The
## demand side for the WeaponsFactory: the army floats a tender for a
## quantity of weapons/ammo and takes the LOWEST bid — a REVERSE auction,
## the mirror image of the Lease auction (there the highest bid wins; here
## undercutting the rival wins, so greed on price risks losing the tender
## and desperation erodes the margin).
##
## Winning locks your price. Delivery pays per unit ON RECEIPT (the army
## pays its bills), full supply on time earns a completion bonus, and
## missing the deadline is a Contract-style penalty.
##
## NOT AUTOPLAY beyond the clock: bid()/close_tender()/deliver() are player
## calls; the deadline rides day_passed once the tender is WON.
##
## Deferred: quality bars on delivered arms (Buyer 19.1 pattern), multi-
## round tenders, reputation with the army, blacklisting after a failure.

enum Status { OPEN, WON, LOST, COMPLETED, FAILED }

# --- The tender on offer ---
@export var tender_name: String = "Army Rifle Tender"
@export var material: String = "weapons"
@export var quantity_required: int = 100
## The rival contractor's sealed per-unit price — beat it by going LOWER.
@export var rival_bid_per_unit: int = 380
## Deadline starts counting when the tender is WON.
@export var days_allowed: int = 60
@export var completion_bonus: int = 2000
@export var penalty: int = 5000
@export var listen_to_clock: bool = true

# --- State ---
var status: Status = Status.OPEN
var my_bid_per_unit: int = 0
var delivered: int = 0
var days_left: int = 0


func _ready() -> void:
	days_left = days_allowed
	if listen_to_clock:
		EventBus.day_passed.connect(_on_day_passed)


# --- Bidding ---

## Lodge (or revise) a sealed per-unit bid. Returns true if it currently
## undercuts the rival (REVERSE auction — lowest price wins).
func bid(price_per_unit: int) -> bool:
	if status != Status.OPEN:
		EventBus.army_action_failed.emit("tender is %s" % status_name())
		return false
	if price_per_unit <= 0:
		EventBus.army_action_failed.emit("bid must be a positive price")
		return false
	my_bid_per_unit = price_per_unit
	var leading: bool = price_per_unit < rival_bid_per_unit
	EventBus.tender_bid_placed.emit(tender_name, price_per_unit, leading)
	return leading


## Close the tender: the lowest bid wins. Returns true if we won it.
func close_tender() -> bool:
	if status != Status.OPEN:
		EventBus.army_action_failed.emit("tender is %s" % status_name())
		return false
	if my_bid_per_unit <= 0:
		status = Status.LOST
		EventBus.tender_lost.emit(tender_name, "no bid was placed")
		return false
	if my_bid_per_unit >= rival_bid_per_unit:
		status = Status.LOST
		EventBus.tender_lost.emit(tender_name, "undercut by the rival contractor")
		return false
	status = Status.WON
	days_left = days_allowed
	EventBus.tender_won.emit(tender_name, my_bid_per_unit)
	return true


# --- Delivery ---

## Deliver up to `amount` against a won tender. The army pays on receipt at
## the locked price. Returns the amount accepted (0 if it couldn't).
func deliver(amount: int) -> int:
	if status != Status.WON:
		EventBus.army_action_failed.emit("tender is %s" % status_name())
		return 0
	var accepted: int = mini(amount, quantity_required - delivered)
	if accepted <= 0:
		EventBus.army_action_failed.emit("nothing more to deliver")
		return 0
	if not GameState.remove_resource(material, accepted):
		EventBus.army_action_failed.emit("not enough %s to deliver" % material)
		return 0

	var paid: int = accepted * my_bid_per_unit
	GameState.add_cash(paid)
	delivered += accepted
	EventBus.army_delivered.emit(tender_name, accepted, paid, delivered, quantity_required)

	if delivered >= quantity_required:
		status = Status.COMPLETED
		GameState.add_cash(completion_bonus)
		EventBus.army_contract_completed.emit(tender_name, completion_bonus)
	return accepted


## Advance the deadline clock (only ticks once WON). Running out before
## full supply FAILS the contract and charges the penalty.
func advance_days(days: int) -> void:
	if status != Status.WON:
		return
	days_left -= days
	if days_left <= 0:
		days_left = 0
		status = Status.FAILED
		GameState.spend_cash(penalty)
		EventBus.army_contract_failed.emit(tender_name, penalty)


# --- Read helpers ---

func status_name() -> String:
	match status:
		Status.OPEN: return "OPEN"
		Status.WON: return "WON"
		Status.LOST: return "LOST"
		Status.COMPLETED: return "COMPLETED"
		_: return "FAILED"


# --- Internal ---

func _on_day_passed(_day: int) -> void:
	advance_days(1)
