extends Node

## Lease — tiny lease-acquisition seed (GAME_PLAN.md section 21). One leasable
## mine/quarry block you acquire from the government, by one of two methods:
##   APPLICATION — pay the set price, then wait out government processing
##                 (advance_days) until it's GRANTED.
##   AUCTION     — bid against a rival; if you outbid them (over the reserve)
##                 you win and pay your bid, otherwise the block is LOST.
## Once GRANTED the block is owned for its term and tied to its one material
## (the constraint a future session enforces when this permits a live mine).
##
## This is the bridge a surveyed ProspectSite (section 20) crosses to become
## an owned right to mine — wiring that link, and spawning the mine, is later.
##
## NOT AUTOPLAY: nothing self-ticks. apply()/bid()/close_auction() are the
## player-triggered entry points; advance_days() is the TimeManager seam that
## counts down the government wait.
##
## Deferred (GAME_PLAN 21.4): corruption/bribes to speed approval & raid risk
## (Session 20); lease EXPIRY & renewal; dynamic rival companies & multi-
## bidder auctions; a real TimeManager driving the wait; the gov-office UI;
## and wiring a granted lease to a ProspectSite / to permitting the mine.
## Numbers are placeholders.

enum Method { APPLICATION, AUCTION }
enum Status { AVAILABLE, PENDING, GRANTED, LOST }

# --- The block on offer (set by world-gen / the government maps) ---
@export var block_name: String = "Block"
@export var material: String = "coal"
@export var area_acres: float = 100.0
@export var term_years: int = 20
@export var method: Method = Method.APPLICATION

# Application terms:
@export var price: int = 50000          # set lease price
@export var approval_days: int = 30     # government processing wait

# Auction terms:
@export var reserve_price: int = 40000  # minimum acceptable bid
@export var rival_top_bid: int = 0      # the best competing bid to beat

# --- State ---
var status: Status = Status.AVAILABLE
var approval_days_left: int = 0
var current_bid: int = 0     # your standing auction bid
var paid: int = 0            # what you ended up paying


# --- Application path ---

## Apply for the lease: pay the price and enter government processing.
func apply() -> bool:
	if method != Method.APPLICATION:
		EventBus.lease_action_failed.emit("%s is auction-only" % block_name)
		return false
	if status != Status.AVAILABLE:
		EventBus.lease_action_failed.emit("%s is already %s" % [block_name, _status_name()])
		return false
	if not GameState.spend_cash(price):
		EventBus.lease_action_failed.emit("not enough cash for the lease price")
		return false

	paid = price
	status = Status.PENDING
	approval_days_left = approval_days
	EventBus.lease_applied.emit(block_name, price)
	return true


## Advance the government wait by `days`. Grants the lease once processing
## completes. (TimeManager seam.)
func advance_days(days: int) -> void:
	if status != Status.PENDING:
		return
	approval_days_left -= days
	if approval_days_left <= 0:
		approval_days_left = 0
		_grant()


# --- Auction path ---

## Place (or raise) your bid. Must clear the reserve. Returns true if your
## bid currently leads the rival's top bid.
func bid(amount: int) -> bool:
	if method != Method.AUCTION:
		EventBus.lease_action_failed.emit("%s is application-only" % block_name)
		return false
	if status != Status.AVAILABLE:
		EventBus.lease_action_failed.emit("%s is already %s" % [block_name, _status_name()])
		return false
	if amount < reserve_price:
		EventBus.lease_action_failed.emit("bid below reserve (%d)" % reserve_price)
		return false

	current_bid = amount
	var leading: bool = amount > rival_top_bid
	EventBus.lease_bid_placed.emit(block_name, amount, leading)
	return leading


## Close the auction: win (pay your bid -> GRANTED) if you outbid the rival,
## otherwise the block is LOST. Returns true if you won it.
func close_auction() -> bool:
	if method != Method.AUCTION:
		EventBus.lease_action_failed.emit("%s is application-only" % block_name)
		return false
	if status != Status.AVAILABLE:
		EventBus.lease_action_failed.emit("%s is already %s" % [block_name, _status_name()])
		return false

	if current_bid <= rival_top_bid:
		status = Status.LOST
		EventBus.lease_lost.emit(block_name, "outbid by a rival")
		return false
	if not GameState.spend_cash(current_bid):
		status = Status.LOST
		EventBus.lease_lost.emit(block_name, "couldn't pay the winning bid")
		return false

	paid = current_bid
	_grant()
	return true


# --- Read helpers ---

func is_granted() -> bool:
	return status == Status.GRANTED


func status_name() -> String:
	return _status_name()


# --- Internal ---

func _grant() -> void:
	status = Status.GRANTED
	EventBus.lease_granted.emit(block_name, material, area_acres, term_years)


func _status_name() -> String:
	match status:
		Status.AVAILABLE: return "AVAILABLE"
		Status.PENDING: return "PENDING"
		Status.GRANTED: return "GRANTED"
		_: return "LOST"
