extends Node

## Buyer — tiny buyers/competition seed (GAME_PLAN.md section 19). The DEMAND
## side of selling: a named buyer with a QUALITY BAR, an agreed price, and a
## deal KIND. Different buyers want different quality of the same material
## (kilns accept low-grade coal; cement wants low-sulfur; a soda-ash plant
## wants very pure aggregate), and reject anything below their bar.
##
## Two deal shapes (section 19.3):
##   INDIVIDUAL — a one-off / few-time spot buyer at the agreed (~market) price.
##   CONTRACT   — a long-term deal: the PRICE IS LOCKED until the contract
##                ends, for a committed quantity (`contract_remaining`). While
##                a contract is live it is EXCLUSIVE — no competitor for that
##                demand (section 19.4) — until it's fulfilled.
##
## NOT AUTOPLAY: nothing self-ticks. deliver() is the player-triggered entry
## point; evaluate() is a read-only preview.
##
## Quality has no SOURCE yet (mine seam quality / crusher purity are deferred,
## see 18.6), so the offered quality is PASSED IN — the seam where it plugs in.
##
## Deferred (GAME_PLAN 19.6): the quality source (sulfur/GCV/purity); payment
## TIMING (advance vs on-delivery — seed pays on delivery); the haggle band;
## rival competitive BIDDING for contracts; middlemen/agents; a marketplace of
## many buyers; and ROYALTY on direct-buyer sales (seed pays gross — unified
## with Market's per-material royalty later). Numbers are placeholders.

enum Kind { INDIVIDUAL, CONTRACT }

# --- The deal (set when the buyer/contract is arranged) ---
@export var buyer_name: String = "Buyer"
@export var material: String = "coal"
## Minimum quality (0.0..1.0) this buyer will accept.
@export var min_quality: float = 0.5
## Agreed price per unit. For a CONTRACT this is LOCKED for its life.
@export var unit_price: int = 50
@export var kind: Kind = Kind.INDIVIDUAL
## Units still committed under a CONTRACT (ignored for INDIVIDUAL).
@export var contract_remaining: int = 0


## Is this buyer still buying? A fulfilled contract is done; individuals
## always buy.
func is_active() -> bool:
	if kind == Kind.CONTRACT:
		return contract_remaining > 0
	return true


## Preview an offer. Returns {"ok": true, accept, price, gross} when the
## buyer would take it, or {"ok": false, reason} when not. A contract caps
## the accepted amount at what's still committed.
func evaluate(quality: float, amount: int) -> Dictionary:
	if not is_active():
		return {"ok": false, "reason": "contract already fulfilled"}
	if amount <= 0:
		return {"ok": false, "reason": "nothing offered"}
	if quality < min_quality:
		return {"ok": false,
			"reason": "quality %.2f below required %.2f" % [quality, min_quality]}

	var accept: int = amount
	if kind == Kind.CONTRACT:
		accept = mini(amount, contract_remaining)
	return {"ok": true, "accept": accept, "price": unit_price, "gross": accept * unit_price}


## Deliver an offer of `amount` at `quality`. Removes the accepted resource
## from GameState and pays cash. Returns the gross paid (0 if refused).
func deliver(quality: float, amount: int) -> int:
	var e: Dictionary = evaluate(quality, amount)
	if not e["ok"]:
		EventBus.buyer_rejected.emit(buyer_name, e["reason"])
		return 0

	var accept: int = e["accept"]
	if not GameState.remove_resource(material, accept):
		EventBus.buyer_rejected.emit(buyer_name, "not enough %s to deliver" % material)
		return 0

	GameState.add_cash(e["gross"])
	if kind == Kind.CONTRACT:
		contract_remaining -= accept
	EventBus.buyer_purchased.emit(buyer_name, material, accept, e["gross"], _kind_name())

	if kind == Kind.CONTRACT and contract_remaining <= 0:
		EventBus.contract_fulfilled.emit(buyer_name)
	return e["gross"]


# --- Internal ---

func _kind_name() -> String:
	return "CONTRACT" if kind == Kind.CONTRACT else "INDIVIDUAL"
