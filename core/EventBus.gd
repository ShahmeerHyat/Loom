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
