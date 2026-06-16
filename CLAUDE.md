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

## Build progress — Sessions 1–12 DONE (verified, committed, pushed)
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

**Resource chain working end-to-end:** LimestoneQuarry → limestone → Crusher →
crush → Grizzly → graded crush; and crush+cement+sand+water → BlockFactory →
blocks. CoalMine/SaltMine feed coal/salt. Truck moves material at a cash cost.

## Next session
**Session 13 — Labor Market** (hire laborers; skill levels, wages, per-block
vs daily-wage deals, seasonal availability). Ties to GAME_PLAN 3.2 and the
"labor chain" seam (work_shift()/run_trip() entry points are where mates →
workers plug in). Get labor domain detail from the user, PLAN FIRST, wait for
OK. (Road coupling into Truck speed/access is still deferred — see §15.5.)

## Known interim shortcuts (documented seams, not bugs)
- Mines/crusher deposit output DIRECTLY into GameState. A later session adds
  per-site stockpiles and reroutes production through trucks (the "interim path"
  comments in those components mark this).
- Everything so far is headless logic verified via print. No HUD / in-world
  interaction yet — that's a future session. Simulation depth is the priority.
- Currency is mixed in flavor ($ in StartMenu, PKR in domain notes); not yet
  calibrated. Numbers like cost_per_trip, prices, blocks_per_shift are
  placeholders to be balanced with the economy later.
