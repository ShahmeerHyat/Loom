extends Node

## WeaponsFactory — licensed arms production (Mega-build: MILITARY). Turns
## our own steel into rifles and ammunition — but ONLY under a government
## arms licence: production without one is refused outright. Weapons and
## ammo are deliberately NOT market goods (the EconomyManager doesn't price
## them) — the army tender (ArmyProcurement.gd) is the only legal buyer.
##
## CORRUPTION SEAM (GAME_PLAN 22.5): acquire_license() pays the official
## fee today; a later slice lets an Official favor waive the fee or the
## processing, and an exposed bribe here should hurt far more than a
## weighbridge one.
##
## NOT AUTOPLAY: acquire_license() / produce_rifles() / produce_ammo() are
## the only entry points.

# --- Tuning (safe to tweak) ---
@export var license_fee: int = 5000
## Rifle batch: steel + power -> weapons.
@export var steel_per_rifle_batch: int = 4
@export var power_per_rifle_batch: int = 3
@export var rifles_per_batch: int = 2
## Ammo batch: steel + coal (case drawing + propellant heat) -> rounds.
@export var steel_per_ammo_batch: int = 1
@export var coal_per_ammo_batch: int = 1
@export var rounds_per_batch: int = 50

# --- State ---
var licensed: bool = false


## Pay the government arms-licence fee. Returns true on success.
func acquire_license() -> bool:
	if licensed:
		EventBus.weapons_action_failed.emit("already licensed")
		return false
	if not GameState.spend_cash(license_fee):
		EventBus.weapons_action_failed.emit("not enough cash for the licence (%d)" % license_fee)
		return false
	licensed = true
	EventBus.weapons_license_acquired.emit(license_fee)
	return true


## One rifle batch: steel + power -> weapons. Licence required.
func produce_rifles() -> void:
	if not _check_license():
		return
	if GameState.get_resource("steel") < steel_per_rifle_batch:
		EventBus.weapons_action_failed.emit("not enough steel (%d needed)" % steel_per_rifle_batch)
		return
	if GameState.get_resource("power") < power_per_rifle_batch:
		EventBus.weapons_action_failed.emit("not enough power (%d needed)" % power_per_rifle_batch)
		return

	GameState.remove_resource("steel", steel_per_rifle_batch)
	GameState.remove_resource("power", power_per_rifle_batch)
	GameState.add_resource("weapons", rifles_per_batch)
	EventBus.weapons_produced.emit(rifles_per_batch)


## One ammunition batch: steel + coal -> rounds. Licence required.
func produce_ammo() -> void:
	if not _check_license():
		return
	if GameState.get_resource("steel") < steel_per_ammo_batch:
		EventBus.weapons_action_failed.emit("not enough steel (%d needed)" % steel_per_ammo_batch)
		return
	if GameState.get_resource("coal") < coal_per_ammo_batch:
		EventBus.weapons_action_failed.emit("not enough coal (%d needed)" % coal_per_ammo_batch)
		return

	GameState.remove_resource("steel", steel_per_ammo_batch)
	GameState.remove_resource("coal", coal_per_ammo_batch)
	GameState.add_resource("ammo", rounds_per_batch)
	EventBus.ammo_produced.emit(rounds_per_batch)


# --- Internal ---

func _check_license() -> bool:
	if not licensed:
		EventBus.weapons_action_failed.emit("no arms licence — acquire_license() first")
		return false
	return true
