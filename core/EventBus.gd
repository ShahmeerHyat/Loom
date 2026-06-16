extends Node

## EventBus — central signal hub for the whole game.
##
## ARCHITECTURE RULE: components never reference each other directly.
## A component emits a signal here, and any interested component connects
## to it here. That keeps every component isolated and safe to vibe-code
## one at a time without breaking the others.
##
## This file should grow slowly. Only add a signal when the component that
## emits it is actually being built. Do not pre-declare future signals.

# --- Game lifecycle signals (Session 4) ---

## Emitted once when the player starts a new company from the start menu.
signal company_started(company_name: String)

# --- Resource / economy signals (Session 1) ---

## Emitted whenever the player's cash changes. Carries the new total.
signal cash_changed(new_amount: int)

## Emitted whenever a tracked resource quantity changes.
## resource_name is one of: "coal", "crush", "blocks".
signal resource_changed(resource_name: String, new_amount: int)

# --- Economy signals (Session 2) ---

## Emitted when the season changes. season_name is one of:
## "DRY", "RAIN", "WINTER", "SUMMER".
signal season_changed(season_name: String)

## Emitted when a sellable good's market price changes.
## good is one of: "coal", "crush", "blocks".
signal price_changed(good: String, new_price: int)

## Emitted when a good's demand multiplier changes (1.0 = normal).
signal demand_changed(good: String, multiplier: float)

## Emitted when a random economic event begins (e.g. flood, tax hike).
## effects is a Dictionary describing what the event does.
signal economic_event_started(event_id: String, description: String, effects: Dictionary)

## Emitted when a previously-started economic event expires.
signal economic_event_ended(event_id: String)

# --- Coal mine signals (Session 5) ---

## Emitted after a shift of digging. Carries how deep the mine now reaches
## and the depth the coal seam sits at (both in feet).
signal mine_dig_progressed(current_depth: float, seam_depth: float)

## Emitted once, the moment the dig first reaches the coal seam.
signal mine_reached_seam()

## Emitted when a shift at the seam produces coal. Carries the amount.
signal mine_coal_produced(amount: int)

# --- Limestone quarry signals (Session 6) ---

## Emitted after a shift of stripping overburden. Carries how much
## overburden has been cleared and the total to clear (both in feet).
signal quarry_strip_progressed(current_overburden: float, overburden_depth: float)

## Emitted once, the moment the overburden is fully stripped and workable
## limestone is exposed.
signal quarry_reached_limestone()

## Emitted when a shift produces raw limestone. Carries the amount.
signal quarry_limestone_produced(amount: int)

# --- Salt mine signals (Session 7) ---

## Emitted after a shift of stripping gypsum overburden. Carries how much
## has been cleared and the total to clear (both in feet).
signal salt_strip_progressed(current_overburden: float, overburden_depth: float)

## Emitted once, the moment the gypsum overburden is fully stripped and the
## salt seam is exposed.
signal salt_reached_seam()

## Emitted when a shift produces salt. Carries the amount.
signal salt_produced(amount: int)

# --- Crusher signals (Session 8) ---

## Emitted when a shift produces crush. Carries the amount.
signal crush_produced(amount: int)

## Emitted when the crusher breaks down (stays down until repaired).
signal crusher_broke_down()

## Emitted when the crusher is repaired and back in operation.
signal crusher_repaired()

## Emitted when a shift can't run for lack of raw limestone to feed it.
signal crusher_no_input()

# --- Grizzly / screening signals (Session 9) ---

## Emitted when a graded-crush tally changes. grade is a size label like
## "20mm" / "13mm" / "6mm" / "dust". Carries the new total for that grade.
signal crush_grade_changed(grade: String, new_amount: int)

## Emitted when the grizzly screens a batch. Carries the crush consumed.
signal grizzly_screened(crush_consumed: int)

## Emitted when a shift can't run for lack of crush to screen.
signal grizzly_no_input()

# --- Block factory signals (Session 10) ---

## Emitted when a shift produces blocks. Carries how many were made.
signal blocks_produced(amount: int)

## Emitted when a shift can't make even one block for lack of materials.
signal blocks_no_input()

# --- Truck / haulage signals (Session 11) ---

## Emitted when a truck completes a trip and delivers cargo into inventory.
## Carries the material, the amount delivered, and the cash cost of the trip.
signal truck_delivered(material: String, amount: int, cost: int)

## Emitted when a trip can't run. reason is a short explanation
## (e.g. "nothing to haul", "not enough cash for trip cost").
signal truck_trip_failed(reason: String)

# --- Road network signals (Session 12) ---

## Emitted whenever a road's quality changes (0.0 impassable dirt .. 1.0
## pristine). Carries the new quality.
signal road_quality_changed(new_quality: float)

## Emitted when a road is repaired. Carries the quality gained and the
## cash cost paid.
signal road_repaired(quality_gained: float, cost: int)

## Emitted the moment a road becomes impassable (e.g. a flood makes a steep
## dirt road too slippery to climb). cause is a short explanation.
signal road_became_impassable(cause: String)

## Emitted the moment a previously-impassable road becomes passable again.
signal road_became_passable()

# --- Labor signals (Session 13) ---

## Emitted when a crew works a shift. Carries the work output produced, the
## wage paid for it (0 for salaried/monthly crews), and the pay type as a
## label ("PER_UNIT", "DAILY", "MONTHLY").
signal labor_shift_worked(output: int, wage_paid: int, pay_type: String)

## Emitted when a crew can't be paid (not enough cash) — the work doesn't
## happen. reason is a short explanation.
signal labor_unpaid(reason: String)

## Emitted when a monthly fixed-staff crew is paid its stipend for a period.
## Carries the total amount paid.
signal labor_stipend_paid(amount: int)

# --- Labor events / hazards (Session 14) ---

## Emitted when some of a crew don't show up for a shift. Carries how many
## were absent and how many turned up.
signal labor_absence(absent: int, present: int)

## Emitted when a worker is injured on a shift. Carries how many were hurt
## and the compensation / medical cost paid.
signal labor_injured(injured: int, cost: int)

## Emitted on a rare catastrophe (e.g. a roof/rock fall when safety rules
## aren't followed). Carries a cause label, how many were hurt, and the cost.
signal labor_accident(cause: String, injured: int, cost: int)

# --- Selling / market signals (Session 15) ---

## Emitted when a good is sold (the "chit"). Carries the good, the amount,
## the gross value, the government royalty deducted, and the net cash gained.
signal good_sold(good: String, amount: int, gross: int, royalty: int, net: int)

## Emitted when a sale can't go through. reason is a short explanation
## (e.g. "not enough coal in stock", "no market price yet").
signal sale_failed(reason: String)

# --- Buyers / competition signals (Session 16) ---

## Emitted when a specific buyer purchases a delivery. Carries the buyer's
## name, the material, the amount taken, the gross paid, and the deal kind
## ("INDIVIDUAL" or "CONTRACT").
signal buyer_purchased(buyer_name: String, material: String, amount: int, gross: int, kind: String)

## Emitted when a buyer refuses a delivery. reason is a short explanation
## (e.g. quality too low, contract already fulfilled, not enough stock).
signal buyer_rejected(buyer_name: String, reason: String)

## Emitted when a contract's committed quantity is fully delivered (its
## exclusivity ends). Carries the buyer's name.
signal contract_fulfilled(buyer_name: String)

# --- Exploration / site survey signals (Session 17) ---

## Emitted after a test bore is drilled on a prospect. Carries the site
## name, how many bores have now been drilled, and the resulting confidence
## (0.0 unknown .. higher = clearer picture).
signal prospect_bored(site_name: String, bores_done: int, confidence: float)

## Emitted when a lab sample comes back, confirming the site's true quality.
signal prospect_lab_result(site_name: String, quality: float)

## Emitted when a survey action can't run. reason is a short explanation
## (e.g. "drill a test bore first", "not enough cash for a test bore").
signal prospect_survey_failed(reason: String)
