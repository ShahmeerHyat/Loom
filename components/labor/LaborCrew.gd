extends Node

## LaborCrew — tiny labor seed (GAME_PLAN.md section 16). Models ONE hired
## crew: a MATE plus a team of laborers under him, with a SKILL factor and a
## negotiated PAY DEAL. Crew size x output-per-worker x skill sets how much
## work the crew can do in a shift — the value a mine/factory will LATER use
## as its throughput driver (replacing today's placeholder dials like the
## block factory's blocks_per_shift).
##
## Three negotiated pay types (section 16.3):
##   PER_UNIT  — paid per unit produced (per block / per amount dug). Cost
##               scales with output; you pay only for what's made.
##   DAILY     — paid a flat daily wage per laborer, regardless of output
##               (project / external labor; the risk on a low-output day).
##   MONTHLY   — fixed staff (cooks, managers, office) on a monthly stipend;
##               NOT charged per shift — paid via pay_period() each period.
##
## NOT AUTOPLAY: nothing self-ticks. work_shift() is the player-triggered
## entry point (the labor-chain seam); pay_period() is triggered by the
## future TimeManager's month tick.
##
## Deferred (GAME_PLAN 16.6): village/region recruiting & skill
## specialization, multiple mates & gallery assignment, donkeys/haulage,
## site-specific crew roles (block-machine vs mixer operator, small crusher
## teams, kilns), seasonal ~3-week leave, advances & hiring cost,
## unionization, disputes/strikes/absenteeism/injury (Session 14), and
## actually wiring crews into each component's throughput. Numbers below are
## placeholders to balance against the economy later.

enum PayType { PER_UNIT, DAILY, MONTHLY }

# --- The deal (set when the crew is hired/negotiated) ---
@export var mate_name: String = "Mate"
## Laborers under the mate.
@export var team_size: int = 10
## Productivity multiplier (1.0 = average). The seam where village/region
## skill specialization plugs in later.
@export var skill: float = 1.0
## Work units one laborer does in a shift (e.g. ft dug, blocks made) before
## skill is applied.
@export var output_per_worker: float = 4.0

@export var pay_type: PayType = PayType.PER_UNIT
## Cash per unit produced (PER_UNIT deals).
@export var per_unit_rate: int = 5
## Cash per laborer per day (DAILY deals) — charged whole, output or not.
@export var daily_wage: int = 300
## Cash per laborer per period (MONTHLY fixed staff).
@export var monthly_stipend: int = 1500


## How much work this crew can do in one shift. The future throughput
## driver for mines/factory.
func productive_capacity() -> int:
	return int(floor(float(team_size) * output_per_worker * skill))


## Work one shift against `available_units` of workable input. Does
## min(capacity, available) work and charges wages by pay model. Returns the
## work output produced (0 if nothing to do, or if the crew couldn't be paid).
func work_shift(available_units: int) -> int:
	var output: int = mini(productive_capacity(), maxi(0, available_units))
	if output <= 0:
		return 0

	var wage: int = _shift_wage(output)
	if wage > 0 and not GameState.spend_cash(wage):
		# No pay, no work — the crew downs tools (a dispute would escalate
		# this in Session 14).
		EventBus.labor_unpaid.emit("not enough cash for wages")
		return 0

	EventBus.labor_shift_worked.emit(output, wage, _pay_type_name())
	return output


## Pay monthly fixed staff their stipend for one period. No-op for crews on
## other pay types. Returns true if paid (or nothing owed), false if the
## stipend couldn't be afforded. Seam for the future TimeManager month tick.
func pay_period() -> bool:
	if pay_type != PayType.MONTHLY:
		return true
	var cost: int = monthly_stipend * team_size
	if cost <= 0:
		return true
	if not GameState.spend_cash(cost):
		EventBus.labor_unpaid.emit("not enough cash for monthly stipend")
		return false
	EventBus.labor_stipend_paid.emit(cost)
	return true


# --- Internal ---

## Wage owed for a shift that produced `output` units, per the pay model.
func _shift_wage(output: int) -> int:
	match pay_type:
		PayType.PER_UNIT:
			return output * per_unit_rate
		PayType.DAILY:
			return daily_wage * team_size
		_:  # MONTHLY — salaried, paid via pay_period(), not per shift
			return 0


func _pay_type_name() -> String:
	match pay_type:
		PayType.PER_UNIT: return "PER_UNIT"
		PayType.DAILY: return "DAILY"
		_: return "MONTHLY"
