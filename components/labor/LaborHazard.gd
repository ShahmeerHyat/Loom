extends Node

## LaborHazard — tiny labor-risk seed (GAME_PLAN.md section 17). Models the
## RISK PROFILE of a job and resolves what happens to a crew over one shift:
## absenteeism, injury, or a rare catastrophe. It is the risk layer that a
## mine/factory will LATER combine with LaborCrew.work_shift().
##
## Risk is a property of the JOB (section 17.1): coal/underground mining is
## dangerous, block-making is comparatively safe. Two dials drive it:
##   DANGER — how hazardous the work is (coal high, blocks low).
##   SAFETY — how well rules / timbering are followed (0 = corners cut,
##            1 = by the book). Low safety spikes catastrophe risk (section
##            17.2); later this is driven by real timber/tunnel-reg state.
##
## NOT AUTOPLAY: nothing self-ticks. resolve_shift() is called for a shift.
## Its random draws are INJECTABLE parameters (default randf()) so the logic
## is deterministically testable and reproducible.
##
## Deferred (GAME_PLAN 17.6): wiring into real mine/factory shifts, the
## annual ~3-week village leave as a seasonal block, tying SAFETY to real
## timber/tunnel-reg state, injury recovery / worker replacement over time,
## pay-driven strikes/disputes (those extend LaborCrew's labor_unpaid seam),
## injury severity tiers, and insurance. Numbers are placeholders.

# --- Job risk profile (set per site) ---
## How hazardous the work is. 0.0 = harmless, 1.0 = extremely dangerous.
@export var danger: float = 0.5
## How well safety rules / timbering are followed. 0.0 = corners cut,
## 1.0 = by the book.
@export var safety: float = 0.7
## Average fraction of a crew that no-shows on a shift (everyday
## absenteeism, separate from the annual village leave).
@export var absentee_rate: float = 0.1

# --- Tuning (safe to tweak) ---
const BASE_INJURY_CHANCE: float = 0.05    # at danger 1.0, safety 0.0
const BASE_ACCIDENT_CHANCE: float = 0.02  # at danger 1.0, safety 0.0
const INJURY_COST: int = 2000             # medical / compensation, one worker
const ACCIDENT_COST: int = 6000           # catastrophe — much larger
const ACCIDENT_INJURY_FRACTION: float = 0.3  # share of crew hurt in a collapse


# --- Pure risk readouts (inspectable: coal mine vs block plant) ---

## Per-shift chance a worker is injured. Scales with danger and poor safety.
func injury_chance() -> float:
	return clampf(BASE_INJURY_CHANCE * danger * (1.0 - safety), 0.0, 1.0)


## Per-shift chance of a catastrophe. Scales with danger and rises sharply
## as safety drops (the "rules not followed -> collapse" case).
func accident_chance() -> float:
	return clampf(BASE_ACCIDENT_CHANCE * danger * pow(1.0 - safety, 2.0), 0.0, 1.0)


# --- Shift resolution ---

## Resolve one shift for a crew of `team_size`. Rolls absenteeism, then a
## catastrophe, then (if no catastrophe) an injury. Charges cash for any
## injury/accident. Returns a result dictionary:
##   present   — workers who turned up
##   absent    — workers who didn't
##   injured   — workers hurt this shift
##   accident  — true if a catastrophe occurred
##   cost      — cash charged this shift
##   can_work  — false if a catastrophe stopped the shift
## The three rolls default to randf() for live play; pass explicit values
## (0.0..1.0) to force outcomes in tests.
func resolve_shift(team_size: int, absence_roll: float = randf(),
		injury_roll: float = randf(), accident_roll: float = randf()) -> Dictionary:
	var absent: int = clampi(
		int(round(float(team_size) * absentee_rate * absence_roll * 2.0)),
		0, team_size)
	var present: int = team_size - absent
	if absent > 0:
		EventBus.labor_absence.emit(absent, present)

	var result: Dictionary = {
		"present": present, "absent": absent, "injured": 0,
		"accident": false, "cost": 0, "can_work": true,
	}

	if accident_roll < accident_chance():
		var hurt: int = maxi(1, int(round(float(present) * ACCIDENT_INJURY_FRACTION)))
		result["injured"] = hurt
		result["accident"] = true
		result["can_work"] = false
		result["cost"] = ACCIDENT_COST
		GameState.spend_cash(ACCIDENT_COST)
		EventBus.labor_accident.emit(
			"roof/rock fall — safety rules not followed", hurt, ACCIDENT_COST)
	elif injury_roll < injury_chance():
		result["injured"] = 1
		result["cost"] = INJURY_COST
		GameState.spend_cash(INJURY_COST)
		EventBus.labor_injured.emit(1, INJURY_COST)

	return result
