extends Node

## Official — tiny corruption/bribery seed (GAME_PLAN.md section 22). A
## role-agnostic, bribeable official you have a (corrupt) relationship with.
## Reusable across the whole business — weighbridge, mine inspector, lease
## clerk, quarry, block site — via the free-string `role`. "Just the cost of
## doing business."
##
## Two shapes of bribe (section 22.2):
##   offer_bribe()  — a ONE-TIME favor (wave an overloaded truck through,
##                    expedite a lease). Risky: it may be EXPOSED -> fine.
##   pay_retainer() — the ONGOING discreet "envelope" that builds TRUST; a
##                    cultivated relationship makes future favors CHEAPER and
##                    SAFER (lower required bribe, lower catch chance).
##
## NOT AUTOPLAY: nothing self-ticks. offer_bribe() / pay_retainer() are the
## player-triggered entry points. The catch roll is injectable (default
## randf()) so outcomes are deterministically testable.
##
## Effects are ABSTRACT in this seed: offer_bribe just reports whether the
## favor was granted. Applying a favor — shortening a Lease wait, passing a
## weighbridge overload, making an inspector overlook a failed safety survey
## (so LaborHazard.safety doesn't bite) — is wired in later sessions. Keeps
## this component isolated.
##
## Deferred (GAME_PLAN 22.5): wiring favors into Lease/weighbridge/inspector/
## safety; raid ESCALATION beyond a fine; accumulating HEAT/reputation across
## many bribes; officials being transferred; UI/flavor. Numbers are placeholders.

# --- The official (set per official) ---
@export var official_name: String = "Official"
@export var role: String = "Inspector"
## What they expect for a favor at zero trust.
@export var expected_bribe: int = 3000
## Chance a bribe is exposed at zero trust (0.0..1.0).
@export var base_catch_chance: float = 0.3
## Relationship level, raised by retainers. Lowers cost and risk.
@export var trust: float = 0.0

# --- Tuning (safe to tweak) ---
const FINE_MULTIPLIER: int = 3        # fine = bribe * this, if caught
const TRUST_PER_RETAINER: float = 0.25
const MAX_TRUST: float = 0.9
const TRUST_COST_DISCOUNT: float = 0.5  # at full trust, bribe costs this much less (fraction)


# --- Read helpers (what a favor will cost / risk right now) ---

## The minimum bribe this official will accept for a favor, given trust.
func required_bribe() -> int:
	return int(expected_bribe * (1.0 - trust * TRUST_COST_DISCOUNT))


## The chance an offered bribe is exposed, given trust.
func catch_chance() -> float:
	return clampf(base_catch_chance * (1.0 - trust), 0.0, 1.0)


# --- Bribery ---

## Offer a one-time bribe for a favor. If it clears `required_bribe()` and can
## be paid, it's accepted; then a roll decides exposure — if caught, a fine is
## paid and the favor FAILS, else the favor is granted. Returns a result:
##   {ok, caught, cost, fine}. `catch_roll` defaults to randf() (inject to test).
func offer_bribe(amount: int, catch_roll: float = randf()) -> Dictionary:
	var req: int = required_bribe()
	if amount < req:
		EventBus.bribe_refused.emit(official_name, "offer below what they expect (%d)" % req)
		return {"ok": false, "caught": false, "cost": 0, "fine": 0}
	if not GameState.spend_cash(amount):
		EventBus.bribe_refused.emit(official_name, "couldn't afford the bribe")
		return {"ok": false, "caught": false, "cost": 0, "fine": 0}

	if catch_roll < catch_chance():
		var fine: int = amount * FINE_MULTIPLIER
		GameState.spend_cash(fine)
		EventBus.bribe_exposed.emit(official_name, fine)
		return {"ok": false, "caught": true, "cost": amount, "fine": fine}

	EventBus.bribe_succeeded.emit(official_name, role, amount)
	return {"ok": true, "caught": false, "cost": amount, "fine": 0}


## Pay a regular "envelope" to build the relationship. Raises trust (capped),
## which makes future bribes cheaper and safer. Returns true if paid.
func pay_retainer(amount: int) -> bool:
	if not GameState.spend_cash(amount):
		EventBus.bribe_refused.emit(official_name, "couldn't afford the retainer")
		return false
	trust = minf(trust + TRUST_PER_RETAINER, MAX_TRUST)
	EventBus.retainer_paid.emit(official_name, amount, trust)
	return true
