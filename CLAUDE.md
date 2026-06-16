# CLAUDE.md — Loom project working context

**READ THIS FIRST, then read `GAME_PLAN.md` in full.** This file tells a fresh
session exactly what Loom is, how we work, what's built, and what's next.
`GAME_PLAN.md` holds the full design vision + domain deep-dives (sections 11–14).

---

## What Loom is
A 2D top-down construction & mining **simulation** (Godot 4.6, GDScript, standard
build — NOT mono). Solo dev, "vibe coded" ONE component per session. You start a
construction company: mines (coal/salt), limestone quarry → crusher → grizzly →
crush, block factory, trucks/logistics, economy with seasons & random events,
later leases/corruption/town/contracts. Depth over graphics. Repo:
https://github.com/ShahmeerHyat/Loom (branch `main`).

## Architecture (do not violate)
- **Event-bus isolation.** Components NEVER reference each other directly. They
  communicate only through `EventBus` (autoload, signal hub) and `GameState`
  (autoload, single source of truth for all data). `core/EventBus.gd` is the
  registry of every signal — read it to see what exists; never pre-declare
  signals for components that don't exist yet.
- **GameState** holds: `cash` (starts 10000), `coal`, `limestone`, `salt`,
  `crush`, `blocks`, `cement`, `sand`, `water`, and `crush_grades` (Dictionary
  grade→amount). All mutations go through methods (`add_resource`,
  `remove_resource`, `spend_cash`, `add_cash`, `add_crush_grade`) that update
  state AND emit the matching EventBus signal.
- **Autoloads (project.godot), in order:** `EventBus`, `GameState`,
  `EconomyManager`.
- **Main scene:** `res://ui/StartMenu.tscn`.
- **NOT AUTOPLAY.** Gameplay components never advance by themselves (no timers).
  Each exposes a single `work_shift()` / `run_trip()` entry point that the player
  triggers. That method is the seam where the future mine-manager → mates →
  workers labor chain will plug in. (Exception: EconomyManager self-ticks via an
  internal Timer, clearly marked "TIME SEAM" to swap for a TimeManager later.)

## How we work each session (STRICT)
1. **One component per session, never two.** Tiny slices of a big vision.
2. **Explain the plan in plain English and WAIT for the user's OK before writing
   code.** (Unless the user explicitly says "build".)
3. Additive changes to core files (EventBus/GameState) are allowed when needed,
   but never refactor working components in an unrelated session.
4. **Capture domain knowledge in GAME_PLAN.md** before/while building, with
   `[UNVERIFIED]` tags where the user flags uncertainty.
5. **Testing:** the user does NOT paste code into the editor (it broke things).
   Instead, create real files `res://test_runner.tscn` (root Node) +
   `res://test_runner.gd` (correct TAB indentation), tell the user to open it and
   press **F6**, and give the EXACT expected output. After the user confirms,
   DELETE the test_runner files.
6. **Git (after each verified session):** stage files EXPLICITLY (never
   `git add -A` — stray editor temp files like `temp.tscn`/`node.tscn` sneak in).
   Commit with a clear message ending `Co-Authored-By: Claude Opus 4.8
   <noreply@anthropic.com>`, then `git push origin main`. `.gd.uid` files ARE
   committed. `.claude/settings.local.json` is gitignored.
7. Keep the working tree clean; delete throwaway/temp files.

## Build progress — Sessions 1–17 + 19–21 DONE (verified, committed, pushed)
## (Session 18 "Site Survey" folded into 17's ProspectSite; numbering keeps GAME_PLAN's list)
1. Core architecture — `core/EventBus.gd`, `core/GameState.gd`.
2. EconomyManager — `core/EconomyManager.gd`: seasons DRY/RAIN/WINTER/SUMMER,
   prices, demand, random events (flood/boom/recession/fuel shock/tax hike).
   Self-ticks (2s = 1 day, 30 days/season).
3. Basic scene — `world/Main.tscn`, `world/Grid.gd` (top-down grid),
   `world/CameraController.gd` (wheel zoom, middle-drag + WASD pan).
4. Mine Office — `ui/StartMenu.gd` + `.tscn`: name company, shows $10,000, then
   loads the world. Added `company_name` + `start_company()` to GameState.
5. CoalMine — `components/mine/CoalMine.gd`: dig IDLE→DIGGING→AT_SEAM to a deep
   seam (1200 ft), then produces coal. `work_shift()` only.
6. LimestoneQuarry — `components/quarry/LimestoneQuarry.gd`: surface, strip
   overburden → extract raw limestone. Added `limestone` resource.
7. SaltMine — `components/mine/SaltMine.gd`: strip gypsum overburden → salt,
   with CUTTING_MACHINE vs EXPLOSIVES output choice (output only, no danger yet).
   Added `salt` resource.
8. Crusher — `components/crusher/Crusher.gd`: consumes limestone → crush, with a
   breakdown/repair mechanic. First CONSUMING component.
9. Grizzly — `components/grizzly/Grizzly.gd`: screens crush into graded sizes
   (20mm/13mm/6mm/dust) in `GameState.crush_grades`. Exact-conservation split.
10. BlockFactory — `components/factory/BlockFactory.gd`: recipe 3 crush : 1
    cement : 6 sand : 1 water → 1 block, capped by `blocks_per_shift` (50,
    PLACEHOLDER — later driven by machine/floor-area sessions). Added cement/
    sand/water resources.
11. Truck — `components/truck/Truck.gd`: `run_trip()` hauls min(capacity,
    available) of a material, charges flat `cost_per_trip` in CASH (first
    cash-spend), delivers into GameState. Bigger trucks cheaper per unit.
12. Road — `components/road/Road.gd`: one steep dirt road with a `quality`
    (0..1, starts bad). Reactive only (no timer): wears from `truck_delivered`
    (scaled by load), degrades on RAIN season (moderate) and `flood` event
    (severe). Flood + steep + low quality → IMPASSABLE (can't climb). Exposes
    `transport_time_multiplier()` / `is_passable()` / `access_multiplier()` for
    the Truck to consult LATER (Truck.gd NOT yet rewired). `repair_road()` is
    the player entry point: flat cash cost = SEAM for the sourced build chain.
13. LaborCrew — `components/labor/LaborCrew.gd`: one crew (mate + team) with a
    `skill` factor and a negotiated `pay_type` (PER_UNIT / DAILY / MONTHLY).
    `productive_capacity()` = team_size × output_per_worker × skill (the future
    throughput driver for mines/factory — replaces placeholder dials like
    blocks_per_shift). `work_shift()` does the work and charges wages by model
    (per-unit scales with output; daily flat per team; monthly = 0 per shift,
    paid via `pay_period()`). No-cash → `labor_unpaid`, no work. NOT wired into
    any existing component yet — standalone, like Road. Session 14 = labor
    EVENTS (strikes/disputes/absenteeism/injury).
14. LaborHazard — `components/labor/LaborHazard.gd`: a job's risk profile
    (`danger`, `safety`, `absentee_rate`). `injury_chance()`/`accident_chance()`
    are pure fns of danger × (1−safety) [accident squares (1−safety) → low
    safety spikes catastrophe]. `resolve_shift(team_size, …rolls)` rolls one
    shift → {present, absent, injured, accident, cost, can_work}, charging cash
    for injuries/accidents. Random draws are INJECTABLE params (default randf())
    → deterministically testable. Standalone (not wired into mines); future
    mine combines LaborCrew.work_shift() + this. Pay-driven strikes still use
    the LaborCrew `labor_unpaid` seam (separate later slice).
15. Market — `components/market/Market.gd`: FIRST REVENUE component. `sell(good,
    amount)` sells coal/crush/blocks at the LIVE market price, deducts a
    PER-MATERIAL govt royalty (`royalty_rates` dict; coal 8% / crush 5% /
    blocks 0%), removes resource + adds net cash, emits `good_sold` (chit) or
    `sale_failed`. `quote()` previews. DECOUPLED: caches prices from EventBus
    `price_changed` (never calls EconomyManager). Inherits season/event price
    swings (rain softens coal etc.) automatically. Deferred §18.6: coal seam
    quality/GCV, buyer types, free sand/dust per-cuft, crush grades, contracts.
16. Buyer — `components/buyers/Buyer.gd`: DEMAND side. A named buyer with a
    `material`, `min_quality` bar, agreed `unit_price`, and `kind` (INDIVIDUAL
    spot vs CONTRACT with locked price + committed `contract_remaining`).
    `evaluate(quality, amount)` previews; `deliver(quality, amount)` rejects
    under-quality/fulfilled/empty/low-stock else removes resource + pays cash;
    contracts cap at remaining, decrement, emit `contract_fulfilled`. Quality
    is PASSED IN (mine seam-quality/crush purity = future source). Standalone;
    pays GROSS (no royalty yet — unify w/ Market later). Signals: buyer_purchased
    / buyer_rejected / contract_fulfilled. Deferred §19.6: quality source,
    payment timing (advance), haggle band, rival BIDDING, agents, many-buyers.
17. ProspectSite — `components/exploration/ProspectSite.gd`: assess a candidate
    mine/quarry block with HIDDEN truth (material, true_seam_depth, true_quality).
    `drill_bore()` (cash) raises `bore_confidence()` (capped 0.9) and NARROWS
    `quality_estimate()`/`depth_estimate()` (low-high bands, unbiased/centered on
    truth); `lab_sample()` (cash, needs ≥1 bore) CONFIRMS exact quality (not
    depth). PRODUCES the quality value Market §18.6 / Buyer §19.6 await (wiring
    into a live mine = later). Deterministic (no RNG). Signals: prospect_bored /
    prospect_lab_result / prospect_survey_failed. Deferred §20.6: gov-maps/auction
    discovery + LEASE (S19), surveyor-as-person, misleading estimates, thickness.
    NOTE: GAME_PLAN §11.9 added — periodic ~7-day internal mine safety survey
    (ties to LaborHazard safety; future mine-ops session).
19. Lease — `components/lease/Lease.gd`: acquire a leasable block (material,
    area_acres, term_years) from the govt via `method`: APPLICATION (`apply()`
    pays price → PENDING; `advance_days(n)` counts down govt wait → GRANTED) or
    AUCTION (`bid(amount)` ≥ reserve, leads vs fixed `rival_top_bid`;
    `close_auction()` → win+pay → GRANTED, else LOST). Status AVAILABLE/PENDING/
    GRANTED/LOST. Signals: lease_applied/granted/bid_placed/lost/action_failed.
    Bridge surveyed ProspectSite → owned right to mine (wiring + one-material
    rule + mine spawn = later). Deferred §21.4: bribes/raids (S20), expiry/
    renewal, dynamic rivals, multi-bidder, real TimeManager wait, gov-office UI.
20. Official — `components/corruption/Official.gd`: CROSS-DOMAIN bribery (free
    `role`: weighbridge/inspector/lease clerk/quarry/blocks). `offer_bribe(amount,
    catch_roll)` grants a favor if ≥ `required_bribe()` & paid, but rolls EXPOSURE
    (< `catch_chance()`) → favor fails + FINE (3× bribe). `pay_retainer(amount)`
    raises `trust` (cap 0.9) which LOWERS required_bribe & catch_chance (ongoing
    relationship cheaper+safer than cold one-off). catch_roll injectable →
    deterministic. Favors ABSTRACT (just reports granted) — wiring into Lease
    wait / weighbridge overload / inspector overlooking LaborHazard safety =
    later. Signals: bribe_succeeded/exposed/refused, retainer_paid. Deferred
    §22.5: favor wiring, raid escalation, heat/reputation, transfers, UI.
21. Town — `components/town/Town.gd`: organic growth loop. `population` +
    per-capita `needs` → `demand_for(good)` scales with pop. `supply(good,
    amount)` takes up to demand, PAYS cash (town buys), adds growth points
    (per-good `growth_weight`); crossing `growth_threshold()` (= pop×0.1) bumps
    population (+100) → demand rises (& next threshold higher). Fails: good not
    needed / not enough stock. Signals: town_supplied / town_grew /
    town_supply_failed. Deferred §23.2: better-labour-from-growth, route demand
    into Market/Buyer, per-period satiation, multiple towns, spatial map.

**Resource chain working end-to-end:** LimestoneQuarry → limestone → Crusher →
crush → Grizzly → graded crush; and crush+cement+sand+water → BlockFactory →
blocks. CoalMine/SaltMine feed coal/salt. Truck moves material at a cash cost.

## Next session
**Session 22 — Construction Contracts** (supply X of a good by date Y for a
reward; penalties for missing; GAME_PLAN 3.6 / 5#22). Builds on Buyer (locked
deals) + Town; first DEADLINE mechanic (needs a day counter — TimeManager seam,
like Lease.advance_days). Get domain detail from the user, PLAN FIRST, wait for
OK.
NEW future design sections now in GAME_PLAN (recorded, NOT built — pick up in
later sessions): §24 POWER/ENERGY (gensets vs grid vs SOLAR capex/opex, land
for panels), §25 LAND & PROPERTY DEVELOPMENT (buy/rent land+buildings, CONSTRUCT
apartments/complexes — size, budget/sqft, unit selling price; Loom is not just
a mining game), and §11.10 slow mine DEPTH CREEP → haulage-upgrade treadmill.
(Still deferred: LaborCrew/LaborHazard→throughput §16.6/17.6; Road→Truck §15.5;
rival bidding & payment timing §19.6; royalty on buyer sales §19.6; lease
expiry/renewal §21.4; ProspectSite→Lease→live mine; corruption favor wiring
§22.5; periodic ~7-day internal mine survey §11.9.)
Remaining plan after 22: Seasonal/Economy event polish (23–24 of the orig list),
UI/sound/Steam (25–28), plus the new Power & Development pillars above.

## Known interim shortcuts (documented seams, not bugs)
- Mines/crusher deposit output DIRECTLY into GameState. A later session adds
  per-site stockpiles and reroutes production through trucks (the "interim path"
  comments in those components mark this).
- Everything so far is headless logic verified via print. No HUD / in-world
  interaction yet — that's a future session. Simulation depth is the priority.
- Currency is mixed in flavor ($ in StartMenu, PKR in domain notes); not yet
  calibrated. Numbers like cost_per_trip, prices, blocks_per_shift are
  placeholders to be balanced with the economy later.
