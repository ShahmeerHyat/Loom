extends Node

## Contract — tiny construction-contract seed (GAME_PLAN.md section 26). A
## deadline-bound bulk supply deal: deliver X of a material by day Y for a
## reward; miss the deadline and you pay a penalty. Builds on the locked-deal
## idea from Buyer (16) and feeds projects / the growing town (23).
##
## This is the first DEADLINE mechanic: advance_days() counts the clock down
## (the same TimeManager seam as Lease.advance_days).
##
## NOT AUTOPLAY: nothing self-ticks. deliver() is the player-triggered entry
## point; advance_days() is the TimeManager seam.
##
## Deferred (GAME_PLAN 26.2): up-front ADVANCE payments & milestone payments;
## quality requirements on delivered goods (ties to Buyer 19.1); competitive
## BIDDING to win the contract (19.4); reputation effects of completing/failing;
## partial-credit vs total loss on failure (seed: partial goods delivered are
## lost, no reward, plus a penalty); a real TimeManager. Numbers are placeholders.

enum Status { ACTIVE, FULFILLED, FAILED }

# --- The deal (set when the contract is signed) ---
@export var client_name: String = "Client"
@export var material: String = "blocks"
@export var quantity_required: int = 1000
@export var days_allowed: int = 30
## Paid in full when the contract is completed on time.
@export var reward: int = 50000
## Charged if the deadline passes before completion.
@export var penalty: int = 10000

# --- State ---
var delivered: int = 0
var days_left: int = 0
var status: Status = Status.ACTIVE


func _ready() -> void:
	days_left = days_allowed


# --- Delivery ---

## Deliver up to `amount` toward the contract (taken from inventory). Completes
## and pays the reward once the required quantity is met. Returns the amount
## accepted (0 if it couldn't).
func deliver(amount: int) -> int:
	if status != Status.ACTIVE:
		EventBus.contract_action_failed.emit("contract is %s" % _status_name())
		return 0

	var accepted: int = mini(amount, quantity_required - delivered)
	if accepted <= 0:
		EventBus.contract_action_failed.emit("nothing more to deliver")
		return 0
	if not GameState.remove_resource(material, accepted):
		EventBus.contract_action_failed.emit("not enough %s to deliver" % material)
		return 0

	delivered += accepted
	EventBus.contract_delivered.emit(client_name, accepted, delivered, quantity_required)

	if delivered >= quantity_required:
		status = Status.FULFILLED
		GameState.add_cash(reward)
		EventBus.contract_completed.emit(client_name, reward)
	return accepted


## Advance the deadline clock by `days`. If it runs out before completion the
## contract FAILS and the penalty is charged. (TimeManager seam.)
func advance_days(days: int) -> void:
	if status != Status.ACTIVE:
		return
	days_left -= days
	if days_left <= 0:
		days_left = 0
		status = Status.FAILED
		GameState.spend_cash(penalty)
		EventBus.contract_failed.emit(client_name, penalty)


# --- Read helpers ---

func status_name() -> String:
	return _status_name()


# --- Internal ---

func _status_name() -> String:
	match status:
		Status.ACTIVE: return "ACTIVE"
		Status.FULFILLED: return "FULFILLED"
		_: return "FAILED"
