# GRAPHICS.md — Loom visual layer working context

**READ THIS when working on a GRAPHICS / VISUAL session.** Sessions 1–22 are
all HEADLESS LOGIC (verified via print, no rendering). This file governs the
NEW phase: textures, sprites, HUD, in-world rendering. It is the visual
counterpart to `GAME_PLAN.md` — same slicing discipline, different concern.
The simulation depth in `GAME_PLAN.md` always leads; **graphics serve the sim.**

---

## 0. THE ONE NON-NEGOTIABLE RULE (read first)
Visuals are **added ALONGSIDE the logic, never inside it.** A visual node:
- **LISTENS** to `EventBus` signals and **READS** `GameState`.
- **NEVER** mutates GameState, never calls a component's `work_shift()`/`sell()`/
  etc., never drives the simulation. (Player input that triggers gameplay is a
  separate later concern — for now visuals are pure observers.)

This is the graphics-equivalent of the event-bus isolation rule. If a visual
script ever writes to `GameState` or calls a component method, it's wrong. A
component must run identically with the visual layer deleted. This keeps the
headless tests valid and lets us vibe-code one visual at a time safely.

---

## 1. VISUAL PILLARS / TARGET STYLE
- **View: ISOMETRIC (2:1 dimetric).** Age of Empires 2 / StarCraft lineage —
  angled camera, diamond ground tiles, buildings drawn as tall sprites with
  visible height/facade. (DECISION: pivoted from top-down before any world art
  was built — see §1a for why and what it costs.) Depth-over-graphics still
  rules — see the NOTE at the end of `GAME_PLAN.md`.
- **Setting:** fictional developing country — mountains, quarries, dirt roads,
  a small growing town (matches GAME_PLAN §2).
- **Tile size:** **128×64 px diamond** (2:1 — the standard dimetric ratio; that
  ratio *is* the angled-camera look). One size used everywhere so tiles + sprite
  footprints line up. Change here if we adopt a different art family's size.
- **Palette:** earthy/industrial (rock greys, dust tan, coal black, rust). Not
  locked yet; refine when we have art in hand.
- **Asset licence:** prefer **CC0 / public domain** so there are no attribution
  or licensing headaches at Steam launch. Kenney.nl is CC0 — but see §4: iso CC0
  art is scarcer than top-down, and CONSISTENCY (one art family) matters more.

## 1a. WHY ISOMETRIC + WHAT IT COSTS (so a future session doesn't second-guess it)
- The pivot was made when the ONLY visuals built were the screen-space HUD (G1/G2,
  perspective-agnostic) and a placeholder square `Grid.gd` — so there was nothing
  to migrate. Cheapest possible moment to choose.
- COST (accepted knowingly): iso buys zero simulation depth and is a heavier art
  burden than top-down — CC0 iso terrain/building art is rarer, every world sprite
  must exist at the iso angle + tile scale, and style consistency is unforgiving.
- The AoE2/SC look is traditionally achieved by **3D-modelling then pre-rendering
  to 2D sprites** at a fixed camera angle (not hand-drawn iso). If we ever need
  bespoke buildings, that Blender→sprite pipeline is the route. Recorded, not yet
  chosen.

## 1b. ISOMETRIC RENDERING FACTS (Godot specifics)
- A `TileMapLayer` with `tile_shape = Isometric` still stores cells as `(x, y)`
  INTEGER coords (same as a square map); Godot only RENDERS them as diamonds and
  converts via `map_to_local()` / `local_to_map()`. We rarely hand-roll iso math.
- **Height illusion = tall sprites + Y-SORT, not the tilemap.** Ground diamonds are
  flat. A building/machine is a tall sprite whose **art origin sits at its ground
  contact point**, drawn on a **Y-sorted** layer (`y_sort_enabled`) so lower-on-
  screen draws in front. THIS IS A NON-NEGOTIABLE for every world sprite (alongside
  §0's listen-don't-drive): consistent footprint, ground-contact origin, Y-sort on.

## 2. RENDERING ARCHITECTURE
- **Where visuals live:** scenes/scripts under `res://world/` (in-world: terrain,
  machine sprites, trucks) and `res://ui/` (HUD, menus, panels). Art files under
  **`res://assets/`** (subfolders: `assets/tiles/`, `assets/sprites/`,
  `assets/ui/`, `assets/fonts/`).
- **What already exists:**
  - `ui/StartMenu.tscn` — main scene (name company → loads world).
  - `world/Main.tscn` — `Node2D` root, with a `Camera2D` (`CameraController.gd`,
    wheel-zoom + middle-drag/WASD pan) and a `Grid` (`Grid.gd`, top-down grid).
  - Autoloads available to every visual: `EventBus`, `GameState`, `EconomyManager`.
- **HUD pattern:** a `CanvasLayer` so the HUD floats above the world and ignores
  camera zoom/pan. HUD = `Control` nodes (`Label`, `HBoxContainer`, etc.).
- **In-world sprite pattern:** a `Sprite2D`/`AnimatedSprite2D` (or small scene)
  placed in the world that connects to the relevant signal in `_ready()` and
  swaps texture/animation/modulate in the handler. Pure reaction.
- **Connecting to signals:** in `_ready()`, e.g.
  `EventBus.cash_changed.connect(_on_cash_changed)`. On startup `GameState._ready()`
  re-emits every resource + cash once, so a HUD that connects at load syncs
  immediately without special-casing initial values.

## 3. SIGNAL → VISUAL MAP (living table)
The contract between sim and view. Add a row when a visual slice starts using a
signal. (Signals are defined in `core/EventBus.gd` — never add a signal here that
isn't already emitted by a built component.)

| Signal (EventBus) | Carries | Visual that should react |
|---|---|---|
| `cash_changed(new_amount)` | new cash total | HUD cash label |
| `resource_changed(name, new_amount)` | resource + total | HUD resource counters (coal/limestone/salt/crush/blocks/cement/sand/water) |
| `crush_grade_changed(grade, new_amount)` | grade + total | HUD/grizzly graded-crush readout |
| `season_changed(season_name)` | DRY/RAIN/WINTER/SUMMER | HUD season indicator; world tint/weather later |
| `price_changed(good, new_price)` | good + price | HUD/market price ticker |
| `economic_event_started/ended(...)` | event id/desc/effects | HUD event banner/toast |
| `mine_dig_progressed` / `mine_reached_seam` / `mine_coal_produced` | depth / amount | coal mine sprite states + depth gauge |
| `quarry_*` / `salt_*` | progress / amount | quarry & salt mine sprite states |
| `crush_produced` / `crusher_broke_down` / `crusher_repaired` / `crusher_no_input` | amount / state | crusher sprite: running / broken / idle |
| `grizzly_screened` / `grizzly_no_input` | consumed | grizzly sprite/animation |
| `blocks_produced` / `blocks_no_input` | amount | block factory sprite + stockpile |
| `truck_delivered` / `truck_trip_failed` | material/amount/cost | truck moving along road; toast on fail |
| `road_quality_changed` / `road_repaired` / `road_became_impassable` / `road_became_passable` | quality / cause | road tile appearance (good→rutted→mud) |
| `labor_*` (shift/unpaid/stipend/absence/injured/accident) | output/wage/counts/cost | worker icons, injury/strike toasts |
| `good_sold` / `sale_failed` | chit fields / reason | sale toast / chit popup |
| `buyer_purchased` / `buyer_rejected` / `contract_fulfilled` | buyer/material/amount | buyer panel + toast |
| `prospect_bored` / `prospect_lab_result` / `prospect_survey_failed` | confidence / quality | survey panel (confidence bar, quality range) |
| `lease_applied` / `lease_granted` / `lease_bid_placed` / `lease_lost` / `lease_action_failed` | block/material/term | lease/government-office panel |
| `bribe_succeeded` / `bribe_exposed` / `bribe_refused` / `retainer_paid` | official/amount/trust | corruption panel + raid/fine toast |
| `town_supplied` / `town_grew` / `town_supply_failed` | good/amount/population | town sprite that grows; supply toast |
| `contract_delivered` / `contract_completed` / `contract_failed` / `contract_action_failed` | client/amounts/reward/penalty | contracts panel + progress bar |

## 4. ASSETS — WHAT THE DEV NEEDS TO DOWNLOAD (and WHEN)
You've never done graphics — here's the plain-English version.

**Types of art you'll hear about:**
- **Texture / sprite** = a PNG image. A *sprite* is just a texture drawn in the
  world (a machine, a truck, a tree). Top-down = drawn from above.
- **Tile / tileset** = small square PNGs (our 64×64) that tile to make ground
  (dirt, rock, grass). Godot's `TileMap` paints these.
- **Font** = a `.ttf`/`.otf` for nicer HUD text (optional; Godot has a default).
- **Animation** = two ways in 2D: (a) a **sprite sheet** (many frames in one PNG)
  played by `AnimatedSprite2D`; or (b) code/`AnimationPlayer`/tween moving or
  fading a single sprite (no art needed). Early on we'll mostly use (b).
- **Audio** comes much later (GAME_PLAN §26) — ignore for now.

**Do you need to download anything right now? NO.**
- The first slice (**G1, the HUD**) is pure Godot UI nodes + the built-in font.
  Zero downloads. We'll do that first precisely so you learn the listen-don't-
  drive pattern before touching art.

**When we DO start drawing the world** (ISOMETRIC — see §1), the plan:
- Go to **https://kenney.nl/assets** → all **CC0** (free, no attribution, safe for
  Steam). For iso, search **"Isometric"** — e.g. isometric tile/landscape and
  building packs. NOTE: Kenney's iso catalogue is smaller than his top-down one.
- Backups: **itch.io** (filter Free + verify CC0/CC-BY) and **OpenGameArt.org**
  (check licence per asset; search "isometric").
- **CONSISTENCY > quantity (iso-specific risk).** Mixing iso art from different
  artists (different camera angle / tile size / light direction) looks broken in a
  way top-down tolerates. Commit to ONE art family and one tile size (§1). If no
  single CC0 family covers everything, the fallback is the Blender→pre-rendered
  sprite pipeline (§1a) — flag it and we decide deliberately.
- Unzip and drop the PNGs into `res://assets/...`. Tell me what's in there (or
  the pack name) and I'll wire the exact files. Keep everything at our tile size.
- I'll always tell you the **exact pack/files** to grab for a given session so you
  never download a random pile of stuff you don't understand.

**Licence hygiene:** prefer CC0. If we ever use CC-BY, we must keep a credits
list — flag it and I'll record it. Avoid anything "non-commercial" (Steam = sale).

## 5. GRAPHICS SESSION LIST (G-series, sliced like GAME_PLAN)
Separate **G-numbering** so it doesn't collide with GAME_PLAN's old "25 UI Polish
/ 26 Sound" items (those fold in here). Same rules: ONE tiny slice per session,
plan-first + wait for OK, verify by opening the scene (F6) — for visuals the
"test" is often *look at it* — then explicit-stage commit + push. This list is a
SEED; grow it as the dev describes the look they want (just like the domain
deep-dives were captured when described).

- **G1 — HUD: cash + resources. ✅ DONE.** `ui/HUD.tscn` + `ui/HUD.gd`: a
  `CanvasLayer` top bar reading cash + all 8 resources; reads GameState on
  `_ready()`, then listens to `cash_changed` / `resource_changed`; instanced into
  `world/Main.tscn`. No art, no downloads. Proved the listen-don't-drive pattern.
  - *Anti-over-scope (held):* display only; no buttons/clicking, no styling beyond
    layout, no `crush_grades` breakdown; never touches a component or GameState.
- **G2 — HUD: season + economy banner. ✅ DONE.** Added a `Season:` label to the
  top bar (initial value read from `EconomyManager.get_current_season()`, then
  updated on `season_changed`) and a `Banners` VBoxContainer that creates a banner
  on `economic_event_started` and removes it on `economic_event_ended`, keyed by
  event id so simultaneous events each clean up. No art. Pure observer.
- **G3 — Isometric ground (`TileMapLayer`, `tile_shape = Isometric`).** First real
  art: a diamond-tiled ground, replacing the placeholder grid. Establishes the iso
  asset pipeline + tile size (§1) and the Y-sort convention (§1b). Requires picking
  ONE iso art family first (§4). Also rebuilds `Grid.gd` as an iso reference grid.
- **G4 — First machine sprite + state.** e.g. the crusher: a sprite that shows
  running / broken / idle off `crush_produced` / `crusher_broke_down` /
  `crusher_repaired`. Static art + modulate/animation by code.
- **G5+ — per-component sprites & panels** (mines, quarry, factory, trucks moving
  on the road, town that visibly grows, survey/lease/contract panels) — one at a
  time, each reading its row in the §3 signal map.

(Order is a suggestion; the dev picks the next slice each session.)

## 6. PROCESS REMINDERS (same discipline as the sim sessions)
- One slice per session. PLAN in plain English and WAIT for OK before code.
- Verify by opening the scene and pressing **F6** (or a `test_runner` where a
  scripted check makes sense). For pure-visual slices, the check is visual.
- Git: stage files EXPLICITLY (never `git add -A`), commit ending
  `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`, then
  `git push origin main`. New art under `res://assets/` is committed too.
- Keep the tree clean; delete throwaway/test files after verifying.
- Update this file's progress + the §3 map as each G-slice lands.
