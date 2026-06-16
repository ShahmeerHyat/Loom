extends Node

## ProspectSite — tiny exploration/assessment seed (GAME_PLAN.md section 20).
## A candidate mine/quarry block whose GEOLOGY is HIDDEN until you pay to
## investigate it. The player drills test bores and sends a lab sample; each
## bore narrows the estimated seam depth & quality, and the lab confirms the
## exact quality.
##
## This is where the `quality` value that Market (18.6) and Buyer (19.6) have
## been waiting on is finally produced — a later session wires a surveyed
## site's quality into the mine it becomes.
##
## NOT AUTOPLAY: nothing self-ticks. drill_bore() and lab_sample() are the
## player-triggered entry points; the estimate readouts are read-only.
##
## The true_* values below are GROUND TRUTH the player cannot see directly
## (world-gen would set them and hide them from UI). Estimates are unbiased
## (centered on truth, band narrows with confidence) for a clean model.
##
## Deferred (GAME_PLAN 20.6): the discovery channel (gov maps / auction) and
## the LEASE / acquisition (section 5 #19); the surveyor as a hireable person;
## MISLEADING / biased estimates; seam thickness & auto-feasibility; world-map
## placement; salt-prospecting specifics; wiring quality into a live mine.
## Numbers are placeholders.

# --- Identity & hidden ground truth (set by world-gen; hidden from player) ---
@export var site_name: String = "Block"
@export var material: String = "coal"
@export var true_seam_depth: float = 1200.0  # ft
@export var true_quality: float = 0.6        # 0.0..1.0

# --- Tuning (safe to tweak) ---
const BORE_COST: int = 1500            # specialist test bore
const LAB_COST: int = 800              # lab sample
const CONFIDENCE_PER_BORE: float = 0.25
const MAX_BORE_CONFIDENCE: float = 0.9  # bores alone never give certainty
const MAX_QUALITY_ERROR: float = 0.40   # half-width at zero confidence
const MAX_DEPTH_ERROR: float = 300.0    # ft, half-width at zero confidence

# --- Survey state ---
var bores_done: int = 0
var lab_confirmed: bool = false


# --- Player-triggered survey actions ---

## Drill one test bore. Costs cash, raises confidence, tightens estimates.
## Returns true if drilled, false if it couldn't be paid for.
func drill_bore() -> bool:
	if not GameState.spend_cash(BORE_COST):
		EventBus.prospect_survey_failed.emit("not enough cash for a test bore")
		return false
	bores_done += 1
	EventBus.prospect_bored.emit(site_name, bores_done, bore_confidence())
	return true


## Send a sample to the lab to confirm the exact quality. Needs at least one
## bore first (you need a hole to sample from). Returns true if confirmed.
func lab_sample() -> bool:
	if bores_done == 0:
		EventBus.prospect_survey_failed.emit("drill a test bore first")
		return false
	if not GameState.spend_cash(LAB_COST):
		EventBus.prospect_survey_failed.emit("not enough cash for a lab sample")
		return false
	lab_confirmed = true
	EventBus.prospect_lab_result.emit(site_name, true_quality)
	return true


# --- Read-only estimates (what the player actually "knows") ---

## Confidence from bores so far (0.0 = unknown), capped — bores alone never
## reach certainty.
func bore_confidence() -> float:
	return minf(float(bores_done) * CONFIDENCE_PER_BORE, MAX_BORE_CONFIDENCE)


## Estimated quality as {known, low, high, confirmed, confidence}. Unknown
## before any bore; an exact value once the lab confirms it.
func quality_estimate() -> Dictionary:
	if lab_confirmed:
		return {"known": true, "low": true_quality, "high": true_quality,
			"confirmed": true, "confidence": 1.0}
	if bores_done == 0:
		return {"known": false}
	var c: float = bore_confidence()
	var hw: float = MAX_QUALITY_ERROR * (1.0 - c)
	return {"known": true, "confirmed": false, "confidence": c,
		"low": clampf(true_quality - hw, 0.0, 1.0),
		"high": clampf(true_quality + hw, 0.0, 1.0)}


## Estimated seam depth (ft) as {known, low, high, confidence}. Unknown
## before any bore; narrows with each bore (the lab does not confirm depth).
func depth_estimate() -> Dictionary:
	if bores_done == 0:
		return {"known": false}
	var c: float = bore_confidence()
	var hw: float = MAX_DEPTH_ERROR * (1.0 - c)
	return {"known": true, "confidence": c,
		"low": maxf(0.0, true_seam_depth - hw),
		"high": true_seam_depth + hw}
