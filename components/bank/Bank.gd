extends Node

## Bank — credit (Mega-build: BANKING). The first way to spend money you
## don't have: one loan at a time up to a credit limit, with interest
## COMPOUNDING DAILY on the TimeManager heartbeat. Repay when you can. Let
## the debt balloon past twice the limit and the bank DEFAULTS you — seizes
## what cash it can and blacklists the company for good.
##
## NOT AUTOPLAY beyond the clock: take_loan() / repay() are player calls;
## daily interest rides day_passed (listen_to_clock).
##
## Deferred: collateral (leases/buildings as security), credit history
## rebuilding after default, multiple competing banks, Islamic financing
## structures, the Official leaning on your loan officer.

enum Status { NO_LOAN, ACTIVE, DEFAULTED }

# --- Tuning (safe to tweak) ---
@export var credit_limit: int = 20000
## Daily compound interest rate (0.01 = 1% per game-day — loan-shark rates;
## calibrate with the economy later).
@export var daily_interest_rate: float = 0.01
## Debt beyond credit_limit × this multiple triggers default.
@export var default_multiple: float = 2.0
@export var listen_to_clock: bool = true

# --- State ---
var status: Status = Status.NO_LOAN
var principal: int = 0


func _ready() -> void:
	if listen_to_clock:
		EventBus.day_passed.connect(_on_day_passed)


# --- Borrowing / repaying ---

## Take a loan (cash arrives immediately). One loan at a time, capped by
## the credit limit, never after a default. Returns true on success.
func take_loan(amount: int) -> bool:
	if status == Status.DEFAULTED:
		EventBus.bank_action_failed.emit("blacklisted after default — no more credit")
		return false
	if status == Status.ACTIVE:
		EventBus.bank_action_failed.emit("an existing loan is outstanding")
		return false
	if amount <= 0:
		EventBus.bank_action_failed.emit("loan must be a positive amount")
		return false
	if amount > credit_limit:
		EventBus.bank_action_failed.emit("over the credit limit (%d)" % credit_limit)
		return false

	principal = amount
	status = Status.ACTIVE
	GameState.add_cash(amount)
	EventBus.loan_taken.emit(amount, principal)
	return true


## Repay up to `amount` of the outstanding principal (capped at what's
## owed). Returns the amount actually repaid.
func repay(amount: int) -> int:
	if status != Status.ACTIVE:
		EventBus.bank_action_failed.emit("no active loan to repay")
		return 0
	var pay: int = mini(amount, principal)
	if pay <= 0:
		EventBus.bank_action_failed.emit("repayment must be a positive amount")
		return 0
	if not GameState.spend_cash(pay):
		EventBus.bank_action_failed.emit("not enough cash to repay %d" % pay)
		return 0

	principal -= pay
	EventBus.loan_repaid.emit(pay, principal)
	if principal <= 0:
		principal = 0
		status = Status.NO_LOAN
	return pay


## Advance `days` of interest. (TimeManager seam / manual for tests.)
func advance_days(days: int) -> void:
	for _i in range(days):
		_accrue_day()


# --- Read helpers ---

func status_name() -> String:
	match status:
		Status.NO_LOAN: return "NO_LOAN"
		Status.ACTIVE: return "ACTIVE"
		_: return "DEFAULTED"


# --- Internal ---

func _on_day_passed(_day: int) -> void:
	advance_days(1)


func _accrue_day() -> void:
	if status != Status.ACTIVE:
		return
	var interest: int = int(ceil(principal * daily_interest_rate))
	principal += interest
	EventBus.loan_interest_accrued.emit(interest, principal)

	if principal > int(credit_limit * default_multiple):
		var seized: int = mini(GameState.cash, principal)
		GameState.spend_cash(seized)
		principal = 0
		status = Status.DEFAULTED
		EventBus.loan_defaulted.emit(seized)
