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

# --- Lease / acquisition signals (Session 19) ---

## Emitted when the player applies for a lease (pays the price, awaits the
## government's processing). Carries the block name and the price paid.
signal lease_applied(block_name: String, price: int)

## Emitted when a lease is granted (by application after the wait, or by
## winning its auction). Carries the block, material, area and term.
signal lease_granted(block_name: String, material: String, area_acres: float, term_years: int)

## Emitted when a bid is placed at an auction. leading is true if the bid
## currently beats the rival's top bid.
signal lease_bid_placed(block_name: String, amount: int, leading: bool)

## Emitted when a lease is lost (outbid at auction, or couldn't pay).
signal lease_lost(block_name: String, reason: String)

## Emitted when a lease action can't run (wrong method, below reserve, not
## enough cash, etc.). reason is a short explanation.
signal lease_action_failed(reason: String)

# --- Corruption / bribery signals (Session 20) ---

## Emitted when a bribe is accepted and the favor is granted. Carries the
## official's name, their role, and the bribe amount paid.
signal bribe_succeeded(official_name: String, role: String, amount: int)

## Emitted when a bribe is exposed — the favor fails and a fine is paid.
## Carries the official's name and the fine.
signal bribe_exposed(official_name: String, fine: int)

## Emitted when a bribe/retainer can't go through (offer too low, no cash).
## Carries the official's name and a short reason.
signal bribe_refused(official_name: String, reason: String)

## Emitted when a regular retainer ("envelope") is paid, building the
## relationship. Carries the official, the amount, and the new trust level.
signal retainer_paid(official_name: String, amount: int, trust: float)

# --- Town growth signals (Session 21) ---

## Emitted when the player supplies the town with goods. Carries the good,
## the amount accepted, the cash revenue, and the growth points gained.
signal town_supplied(good: String, amount: int, revenue: int, growth: int)

## Emitted when the town's population grows past a threshold. Carries the
## new population.
signal town_grew(population: int)

## Emitted when a supply can't go through (good not needed, not enough
## stock). reason is a short explanation.
signal town_supply_failed(reason: String)

# --- Construction contract signals (Session 22) ---

## Emitted when goods are delivered toward a contract. Carries the client,
## the amount just delivered, the running total, and the quantity required.
signal contract_delivered(client_name: String, amount: int, delivered: int, required: int)

## Emitted when a contract is completed (fully delivered before the deadline).
## Carries the client and the reward paid.
signal contract_completed(client_name: String, reward: int)

## Emitted when a contract fails (deadline passed before completion). Carries
## the client and the penalty charged.
signal contract_failed(client_name: String, penalty: int)

## Emitted when a contract action can't run (already settled, not enough
## stock). reason is a short explanation.
signal contract_action_failed(reason: String)

# --- Time signals (Mega-build: TimeManager) ---

## Emitted once per game-day by TimeManager — the single heartbeat every
## day-based system listens to. Carries the day number (1-based, ever up).
signal day_passed(day: int)

# --- Terrain signals (Mega-build: TerrainData) ---

## Emitted once when the world terrain model is ready to be queried.
signal terrain_generated(width: int, height: int)

# --- Farm land signals (Mega-build: FARMING) ---

## Emitted when an agricultural parcel is bought. Carries the parcel name,
## its size, and the cash paid.
signal farm_land_purchased(parcel_name: String, acres: float, cost: int)

## Emitted when irrigation (a tubewell) is installed on an owned parcel.
signal farm_irrigation_installed(parcel_name: String, cost: int)

## Emitted when a farm-land action can't run (already owned, no cash, etc.).
signal farm_action_failed(reason: String)

# --- Crop signals (Mega-build: FARMING) ---

## Emitted when a crop is sown. season_ok is false when it was sown out of
## its proper season (germination suffers).
signal crop_sown(crop_type: String, acres: float, season_ok: bool)

## Emitted each day a crop grows. Carries progress toward maturity.
signal crop_progressed(crop_type: String, days_grown: int, growth_days: int)

## Emitted on a day the crop couldn't drink (not enough water) — stress
## builds toward yield loss and, eventually, a dead crop.
signal crop_stressed(crop_type: String, stress_days: int)

## Emitted when fertilizer is applied. Carries the running application
## count and the resulting yield multiplier (over-application burns).
signal crop_fertilized(crop_type: String, applications: int, yield_multiplier: float)

## Emitted the day a crop reaches maturity (ready to harvest — don't wait
## too long or it rots in the field).
signal crop_matured(crop_type: String)

## Emitted when a mature crop is harvested. Carries the units banked.
signal crop_harvested(crop_type: String, amount: int)

## Emitted when a crop dies (drought stress) or rots (left unharvested).
signal crop_failed(crop_type: String, reason: String)

## Emitted when a crop action can't run (wrong state, no seeds, etc.).
signal crop_action_failed(reason: String)

# --- Farm equipment signals (Mega-build: FARMING) ---

## Emitted when a machine (tractor / harvester / thresher) is bought.
signal equipment_purchased(equipment_name: String, kind: String, cost: int)

## Emitted when a machine works a task, burning fuel.
signal equipment_worked(equipment_name: String, fuel_used: int)

## Emitted when a machine breaks down (stays down until repaired).
signal equipment_broke_down(equipment_name: String)

## Emitted when a broken machine is repaired. Carries the cash cost.
signal equipment_repaired(equipment_name: String, cost: int)

## Emitted when an equipment action can't run (not owned, no fuel, etc.).
signal equipment_action_failed(reason: String)

# --- Iron mine signals (Mega-build: STEEL CHAIN) ---

## Emitted after a shift of digging toward the iron seam.
signal iron_dig_progressed(current_depth: float, seam_depth: float)

## Emitted once, the moment the dig first reaches the iron seam.
signal iron_reached_seam()

## Emitted when a shift at the seam produces iron ore. Carries the amount.
signal iron_ore_produced(amount: int)

# --- Steel factory signals (Mega-build: STEEL CHAIN) ---

## Emitted when the blast furnace is fired up (a big coal charge). Carries
## how many shifts of heat the firing bought.
signal furnace_fired(heat_shifts: int)

## Emitted when a hot-furnace shift produces steel. Carries the amount.
signal steel_produced(amount: int)

## Emitted when the furnace runs out of heat and goes cold (fire it again).
signal furnace_cooled()

## Emitted when the furnace lining wears out — no more shifts until relined.
signal furnace_lining_worn()

## Emitted when a worn furnace is relined. Carries the cash cost.
signal furnace_relined(cost: int)

## Emitted when a steel-factory action can't run (cold furnace, no ore,
## no coal, no power, lining worn). reason is a short explanation.
signal steel_action_failed(reason: String)

# --- Cement factory signals (Mega-build: STEEL CHAIN) ---

## Emitted when a kiln shift produces cement. Carries the amount.
signal cement_produced(amount: int)

## Emitted when a cement shift can't run (no limestone / coal / power).
signal cement_action_failed(reason: String)

# --- Weapons factory signals (Mega-build: MILITARY) ---

## Emitted when the government arms licence is acquired. Carries the fee.
signal weapons_license_acquired(cost: int)

## Emitted when a shift produces rifles. Carries the amount.
signal weapons_produced(amount: int)

## Emitted when a shift produces ammunition. Carries the rounds made.
signal ammo_produced(amount: int)

## Emitted when a weapons action can't run (no licence, no steel, etc.).
signal weapons_action_failed(reason: String)

# --- Army procurement signals (Mega-build: MILITARY) ---

## Emitted when a bid is lodged on an army tender. REVERSE auction: the
## LOWEST price wins, so leading means our price undercuts the rival's.
signal tender_bid_placed(tender_name: String, price_per_unit: int, leading: bool)

## Emitted when the tender closes in our favour. Carries the locked price.
signal tender_won(tender_name: String, price_per_unit: int)

## Emitted when the tender is lost. reason is a short explanation.
signal tender_lost(tender_name: String, reason: String)

## Emitted when goods are delivered against a won tender. The army pays on
## receipt at the locked per-unit price.
signal army_delivered(tender_name: String, amount: int, paid: int, delivered: int, required: int)

## Emitted when a won tender is fully supplied on time. Carries the bonus.
signal army_contract_completed(tender_name: String, bonus: int)

## Emitted when the deadline passes before full supply. Carries the penalty.
signal army_contract_failed(tender_name: String, penalty: int)

## Emitted when a procurement action can't run. reason is short.
signal army_action_failed(reason: String)

# --- Power signals (Mega-build: POWER) ---

## Emitted when power is generated. source is "genset" or "solar".
signal power_generated(source: String, amount: int)

## Emitted when the genset can't run for lack of fuel.
signal genset_no_fuel()

## Emitted when the genset breaks down (stays down until repaired).
signal genset_broke_down()

## Emitted when the genset is repaired. Carries the cash cost.
signal genset_repaired(cost: int)

## Emitted when a solar array is bought and installed. Carries the capex.
signal solar_installed(cost: int)

## Emitted when a power action can't run (not installed, no cash, etc.).
signal power_action_failed(reason: String)

# --- Property signals (Mega-build: PROPERTY) ---

## Emitted when a construction shift advances a building.
signal construction_progressed(building_name: String, points: int, points_required: int)

## Emitted once when a building's construction completes (rent can flow).
signal building_completed(building_name: String)

## Emitted each day a completed building accrues rent (uncollected).
signal rent_accrued(building_name: String, amount: int)

## Emitted when accrued rent is collected into cash.
signal rent_collected(building_name: String, amount: int)

## Emitted when a property action can't run (no materials, nothing accrued).
signal property_action_failed(reason: String)

# --- Bank signals (Mega-build: BANKING) ---

## Emitted when a loan is disbursed. Carries the cash received and the
## opening principal.
signal loan_taken(amount: int, principal: int)

## Emitted each day interest compounds onto an active loan.
signal loan_interest_accrued(interest: int, principal: int)

## Emitted when a repayment is made. principal is what remains (0 = clear).
signal loan_repaid(amount: int, principal: int)

## Emitted when a ballooned loan defaults — the bank seizes what it can and
## blacklists the company. Carries the cash seized.
signal loan_defaulted(seized: int)

## Emitted when a bank action can't run (existing loan, over limit, etc.).
signal bank_action_failed(reason: String)

# --- Fuel depot signals (Mega-build: FUEL) ---

## Emitted when fuel is bought. Carries the litres and the cash paid.
signal fuel_purchased(litres: int, cost: int)

## Emitted when the pump price moves (e.g. a fuel_shock event doubles it).
signal fuel_price_changed(price_per_litre: int)

## Emitted when a fuel purchase can't go through. reason is short.
signal fuel_purchase_failed(reason: String)

# --- Warehouse signals (Mega-build: STORAGE) ---

## Emitted when material is moved into site storage. used/capacity report
## how full the warehouse now is.
signal warehouse_stored(material: String, amount: int, used: int, capacity: int)

## Emitted when material is withdrawn from site storage back to inventory.
signal warehouse_withdrawn(material: String, amount: int)

## Emitted when a warehouse action can't run (full, nothing stored, etc.).
signal warehouse_action_failed(reason: String)
