extends Node

## Market — tiny spot-selling seed (GAME_PLAN.md section 18). The first
## REVENUE component (counterpart to the Truck's first cash-spend). Sells the
## three goods EconomyManager already prices (coal / crush / blocks) at the
## LIVE market price, deducts a PER-MATERIAL government royalty, removes the
## resource from inventory and adds the net cash. Each sale emits a
## `good_sold` "chit".
##
## ARCHITECTURE: stays decoupled. It does NOT call EconomyManager — it caches
## the latest price per good from the EventBus `price_changed` signal, and
## moves goods/cash only through GameState. (Components talk only via EventBus
## + GameState.)
##
## NOT AUTOPLAY: nothing self-ticks. sell() is the player-triggered entry
## point; quote() is a read-only preview.
##
## Deferred (GAME_PLAN 18.6): coal seam QUALITY (thickness/sulfur/GCV) &
## extraction feasibility; buyer TYPES (cement vs kiln) & reliability & daily
## truck arrivals & quality requirements; FREE sand/dust by-product (loading
## + transport only) priced per cubic foot; selling crush GRADES; the
## blocks-per-piece nuance (seed uses the per-unit price); ANNUAL CONTRACTS &
## competitive bidding; the manual discount lever; royalty timing/accrual
## (seed pays on the spot). Royalty rates below are placeholders.

# --- Tuning (safe to tweak) ---
## Goods this market will buy. (Matches EconomyManager's priced GOODS.)
const SELLABLE: Array[String] = ["coal", "crush", "blocks"]

## Government royalty rate per material (section 18.4). Differs by material;
## blocks are a manufactured good, so no extraction royalty. Placeholders.
@export var royalty_rates: Dictionary = {
	"coal": 0.08,
	"crush": 0.05,
	"blocks": 0.0,
}
## Royalty applied to any sellable good not listed above.
const DEFAULT_ROYALTY: float = 0.05

# --- State ---
## Latest market price per good, kept fresh from EventBus.price_changed.
var _prices: Dictionary = {}


func _ready() -> void:
	EventBus.price_changed.connect(_on_price_changed)


# --- Selling ---

## Preview a sale without performing it. Returns a Dictionary with "ok":
## true and {good, amount, price, gross, royalty, net} when sellable, or
## "ok": false and a "reason" when not.
func quote(good: String, amount: int) -> Dictionary:
	if not SELLABLE.has(good):
		return {"ok": false, "reason": "'%s' is not sold here yet" % good}
	if not _prices.has(good):
		return {"ok": false, "reason": "no market price for %s yet" % good}
	if amount <= 0:
		return {"ok": false, "reason": "nothing to sell"}

	var price: int = int(_prices[good])
	var gross: int = price * amount
	var royalty: int = int(gross * _royalty_rate(good))
	return {
		"ok": true, "good": good, "amount": amount, "price": price,
		"gross": gross, "royalty": royalty, "net": gross - royalty,
	}


## Sell `amount` of `good` at the live market price, net of royalty. Returns
## the net cash gained (0 if the sale couldn't go through).
func sell(good: String, amount: int) -> int:
	var q: Dictionary = quote(good, amount)
	if not q["ok"]:
		EventBus.sale_failed.emit(q["reason"])
		return 0

	# Take the goods first; if stock is short, nothing is sold.
	if not GameState.remove_resource(good, amount):
		EventBus.sale_failed.emit("not enough %s in stock" % good)
		return 0

	GameState.add_cash(q["net"])
	EventBus.good_sold.emit(good, amount, q["gross"], q["royalty"], q["net"])
	return q["net"]


# --- Read helpers ---

## Current cached market price for a good (0 if none seen yet).
func market_price(good: String) -> int:
	return int(_prices.get(good, 0))


# --- Internal ---

func _royalty_rate(good: String) -> float:
	return float(royalty_rates.get(good, DEFAULT_ROYALTY))


func _on_price_changed(good: String, new_price: int) -> void:
	_prices[good] = new_price
