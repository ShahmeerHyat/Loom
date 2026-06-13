# LOOM — Game Design & Development Plan
## 2D Top-Down Construction & Mining Simulation (Godot 4.6, GDScript)

## 1. GAME CONCEPT (Original Description)
Start a construction company. You make mines, deal with laborers (wood, materials, mine equipment, trucks, rods up to the mines). Then exploration — maps and terrains to find places for new mines like salt mines, which is a different expertise and skill set to manage and set up. Also limestone quarries, setting up limestone crushers and grizzly machines to get crush. You can sell crush and coal to other users, or have crush dumped at the site and transported to other sites. For example set up a place adjacent to the mine — a small amount of crush used in making concrete blocks to help construction of a small tiny town nearby. But you can't just make 100,000 blocks a day and sell because there aren't enough people buying. Demand of materials is tied to seasons: rain season closes brick kilns, coal slows down. A flood disaster spikes construction demand and block prices. Bricks aren't used by poor societies who can't afford them. The country economy also shifts things like taxes (this part is partly out of player control). Also acquisition of leases, corruption and bribes.

## 2. GAME OVERVIEW
- Title: Loom (working title)
- Genre: Construction / Resource Management / Simulation
- Platform: PC — Steam
- Engine: Godot 4.6, GDScript
- View: 2D top-down (Factorio / RimWorld style)
- Setting: Fictional developing country — mountains, quarries, towns
- Development: Solo, vibe coded, one component per session
- Target Price: $15–20 Steam Early Access
- Inspiration: Schedule 1, Factorio, RimWorld, Workers & Resources

## 3. CORE GAME SYSTEMS

### 3.1 Resource Chain
- Acquire mining lease (paperwork, corruption, bribes)
- Set up mine — salt, coal, limestone quarry
- Extract raw materials
- Process — crusher + grizzly machine → crush
- Transport — trucks carry materials between sites
- Manufacture — crush + materials = concrete blocks
- Sell to market OR use for local construction

### 3.2 Labor System
- Hire laborers — skill levels, wages
- Per-block rate vs daily wage deals
- Shifts, fatigue, absenteeism, strikes, disputes
- Seasonal labor availability

### 3.3 Economy System (partly out of player control)
- Demand tied to seasons (rain closes kilns, slows coal)
- Disasters (floods) spike construction demand and prices
- Class-based demand — poor areas can't afford blocks
- Country economy shifts — random taxes, duties
- Other players/AI buying your materials
- Supply/demand you can't fully predict

### 3.4 Exploration System
- Terrain maps — explore to find new mine sites
- Sites differ in yield quality, accessibility
- Salt / coal / limestone — each a unique setup
- Road building to reach remote sites
- Survey before lease application

### 3.5 Lease & Corruption System
- Apply for leases through government offices
- Bribe officials to speed up (risk: raids, fines)
- Lease expiry and renewal
- Competing companies acquiring leases

### 3.6 Construction System
- Nearby town grows as you supply materials
- Town demand drives production targets
- Concrete block factory adjacent to quarry
- Construction contracts — supply X by date Y

## 4. CODE ARCHITECTURE (Vibe Coding Safe)
Built on an Event System so every component is isolated. No component talks directly to another — everything goes through a central event bus (Godot signals). Each session works on ONE component without breaking others.

Core files (rarely change):
- EventBus — central signal-based event system
- GameState — single source of truth for all game data
- ResourceManager — tracks coal, crush, blocks, cash
- TimeManager — game time, seasons, day/night
- EconomyManager — prices, taxes, demand (the uncontrollable layer)

Folder structure:
res://
  core/        (EventBus, GameState, ResourceManager, TimeManager, EconomyManager)
  components/  (mine, crusher, trucks, laborers, market, exploration, lease, construction, town)
  ui/
  assets/

How the event system works: each component broadcasts events and listens for events. Example: Mine emits "coal_extracted" → Truck listens for it → Crusher listens to truck's "delivery_arrived" → Market listens to crusher's "crush_produced". Change the Mine and Truck/Crusher/Market don't care — they just listen for signals.

## 5. DEVELOPMENT SESSIONS (one component each)
1. Core Architecture — EventBus, GameState, ResourceManager, TimeManager
2. Economy Engine — EconomyManager: seasons, prices, demand, random events
3. Basic Scene — 2D top-down map, camera, grid
4. Mine Office — start UI, company name, starting cash
5. Mine Setup — coal mine: workers, extraction rate, output
6. Limestone Quarry — same structure, different output
7. Salt Mine — unique mechanics
8. Crusher Machine — raw limestone → crush, breakdown mechanic
9. Grizzly Machine — sorting, crush grades
10. Block Factory — crush + materials → blocks, production limits
11. Truck System — hire, assign routes, carry between sites
12. Road Network — build roads, road quality affects speed
13. Labor Market — hire, wages, skills, seasonal availability
14. Labor Events — strikes, disputes, absenteeism, injury
15. Selling System — sell crush/coal/blocks at economy prices
16. Other Buyers — AI companies, competition
17. Map / Exploration — discover new mine sites
18. Site Survey — survey before lease
19. Lease System — apply, government office, wait times
20. Corruption System — bribes, risk/reward, raids
21. Town Growth — town grows as you supply
22. Construction Contracts — supply X by date Y
23. Seasonal Events — rain, floods, droughts
24. Economy Events — random taxes, policy shifts
25. UI Polish — menus, HUD, all screens
26. Sound Design — ambient, machinery, weather
27. Steam Setup — store page, screenshots, $100 fee
28. Early Access launch — ship sessions 1-16, add rest as updates

## 6. WORKED EXAMPLE — Block-Making Site Setup (the depth the game is built on)
Phase 1 — Site Prep: survey ground type; if unsuitable hire loaders/tractors to clear; compaction (multiple days, paid labor); leveling; floor laying (calculate size, buy steel/rebar, place lenter); buy cement+sand for floor pour.
Phase 2 — Infrastructure: block machine (new=expensive/reliable vs used=cheap/repair risk); mixer machine same choice; used = find mechanic, parts, downtime; electricity connection (fee, wait); water (drill bore, buy cement rings, stack, plaster, cure); labor shelter.
Phase 3 — Labor Deal: negotiate per-block rate OR daily wage; advances; work only starts after deal.
Phase 4 — Raw Materials: crush (own quarry or buy); cement (local agent markup OR factory-direct with contacts); sand source+transport; water from bore.
Phase 5 — Logistics: cost per trip vs load size; big loads = fewer trips = cheaper; BUT weighbridge scales check trucks; overload = fines/confiscation; find alternate routes, split loads, or deal with scale.
Only after ALL of this does the first block get made. Every other game skips this — you click a button. Here the player earns it. That process IS the game.

## 7. VIBE CODING RULES (every session)
1. Build ONE component per session, never two
2. Use the event system — components never directly reference each other
3. Tell the AI exactly which component, nothing else
4. Never let AI refactor/touch existing working components
5. Test each component alone before next session
6. Commit to GitHub at end of every session
7. If AI starts touching unrelated files — stop, start fresh
8. Make AI explain its plan before writing code

## 8. ENGINE & TOOLS
- Godot 4.6 (GDScript, standard build — NOT mono)
- Claude Code — vibe coding, reads/writes .gd and .tscn files in project folder
- GitHub — version control
- Kenney.nl / itch.io / OpenGameArt — free 2D assets
- Steam Direct — publish ($100 one time)
- Payoneer — receive Steam payouts in Pakistan

## 9. MONETIZATION
- Early Access launch ~$15 (sessions 1-16 done)
- Updates add systems, price rises to $18 then $20
- DLC: new regions
- Steam pays monthly → Payoneer → Pakistani bank (no LLC needed)

## 10. TIMELINE (realistic, solo, vibe coded)
- Month 1: Foundation (sessions 1-3)
- Month 2: Mining core (4-9)
- Month 3: Full resource chain (10-14)
- Month 4: Market + selling (15-16)
- Month 4-5: Early Access launch — core loop done, start earning
- Month 6-9: Exploration, legal, town, contracts (17-22)
- Month 10-12: Polish, sound, full release

## 11. DOMAIN DEEP-DIVE: COAL MINE MECHANICS (design reference)
> Captured from real-world domain knowledge. This is the FULL target depth for the coal mine. It will be built across MANY small sessions — never all at once. Session 5 implements only a tiny first slice (see 11.8).

### 11.1 Lease & Allocation
- Apply to the government for a mining lease.
- Granted after a wait; the term varies by material (e.g. coal 10–30 years).
- The lease ties you to ONE material and a specific land block / area — you may only extract what the lease is granted for.

### 11.2 Opening the Mine
- Hire a mine manager.
- Construct the "mouth of the mine" (the entrance / portal).
- Hire mine mates — each mate leads a team of ~10–30 workers under them.
- Workers have donkeys that carry coal out (early/default haulage).

### 11.3 Reaching the Coal (the dig)
- Coal sits deep; depth is known beforehand from boring & exploration (e.g. ~1200 ft). You do NOT hit coal immediately.
- Dig rate ≈ 4 ft/day per worker pair, modified by rock hardness (soft rock faster, hard rock slower).
- Double shift (2 teams, paid more) ≈ 8 ft/day.
- Coal pockets: small pockets are found on the way down (~700–800 ft) and give early partial income to start offsetting the heavy costs of digging.

### 11.4 Timber (a major sunk cost)
- Tunnels must be held open with timber, placed at frequent increments along the tunnel.
- Eucalyptus: cheaper (still expensive), shorter lifespan (e.g. ~6 months) — replaced often.
- Stronger/rarer wood: much more expensive but lasts ~10× longer (e.g. ~5 years).
- Timber is one of the biggest money sinks when opening a mine, alongside labor.

### 11.5 Tunnel Regulations
- Legal minimum tunnel height (e.g. 6 ft), varies by province / local law.
- A higher requirement means more dirt removed = significantly higher operating cost.

### 11.6 At the Seam: Galleries & Haulage
- The main tunnel branches into galleries (holes); each gallery is usually assigned to a different mate's team.
- Crosses are cut between galleries for ventilation.
- Once at the seam, you advance ALONG the coal seam — slower than the straight, narrow approach tunnel was.
- Haulage options:
  - Donkeys carry coal out from the seam (default, cheap, low throughput).
  - Rail system: lay rails first (best when the tunnel is dug straight), use 1–2 tonne carriages, and a diesel haulage/engine pulls the carts out from thousands of feet deep to be dumped at the surface. High upfront cost, far better throughput.

### 11.7 Ventilation & Water
- Big industrial fans placed at mine entry/exit.
- Ventilation crosses between galleries.
- Pumps used in rain season for low-altitude / flood-prone mines.

### 11.8 How this will be sliced (anti-over-scope)
The above is the full vision, NOT one session. It maps onto many future sessions in tiny increments — lease (≈ Session 19), the dig (depth, rock hardness, dig rate, shifts), timber upkeep, mates & workers, donkeys vs rail haulage, galleries, ventilation, flooding/pumps — each its own later slice. Session 5 builds only the smallest playable seed of the coal mine; everything else is layered on one session at a time.

## 12. DOMAIN DEEP-DIVE: SALT MINE MECHANICS (design reference)
> Based on SECONDHAND domain knowledge (a family member's experience, not the designer's own). Items flagged [UNVERIFIED] must be confirmed before they are built. Like the coal deep-dive, this is the FULL vision, sliced across many sessions — Session 7 builds only the smallest seed (see 12.6).

### 12.1 Identification & Geology
- Salt is identified by boring / survey, which reveals the salt channel/seam depth.
- The salt seam usually sits under a gypsum overburden layer.

### 12.2 Mine Form & Haulage
- Unlike coal's deep vertical descent, salt mines are WIDE adits driven horizontally into a mountainside.
- Because of this there are NO donkeys — haulage is carts / loaders / trucks directly.
- [UNVERIFIED: whether the workings are fully underground.]

### 12.3 Extraction Methods (risk / reward choice)
- Cutting machines: slower output, safer.
- Explosives / blasting: higher output, more dangerous.
- Salt comes out as rock, then loaded and transported.

### 12.4 Shared Backbone (same as coal)
- Lease, mine manager, mates / workers, site setup, transport — the salt mine reuses the same backbone as the coal mine.

### 12.5 Processing Plant (future — a much later session)
- A build-it-yourself salt processing plant following the same philosophy (buy equipment, hire labor, set up site, transport — never autoplay).
- Steps may include washing and powder / grinding.
- [UNVERIFIED: the exact processing method.]
- [UNVERIFIED: grinding possibly done with a crusher.]
- [UNVERIFIED: a packaging step.]

### 12.6 How this will be sliced (anti-over-scope)
The above is the full vision, NOT one session. Session 7 builds ONLY the smallest seed: strip gypsum overburden -> reach salt seam -> produce salt, with a cutting-machine-vs-explosives choice that for now changes only output per shift (no danger/accident mechanic). Deferred: donkeys/haulage, processing plant (washing/grinding/packaging), lease, mates hiring, danger/accidents & blasting risk, transport, world placement, UI.

## 13. DOMAIN DEEP-DIVE: LIMESTONE QUARRY & CRUSHER PLANT (design reference)
> Captured from the designer's direct domain knowledge. This is the FULL vision; it is sliced across many sessions (Session 8 = primary crush, Session 9 = grizzly/screening, with later sessions for power, labor, conveyors, trucks). [UNVERIFIED] marks points the designer was unsure about.

### 13.1 Two Parts of a Quarry Operation
A limestone operation has two parts: (1) quarrying / excavation on the mountain, and (2) the crusher plant that turns big rock into saleable aggregate.

### 13.2 Part 1 — Quarrying (excavation)
- An excavator (operated by its driver) digs out big blocks of limestone on the mountain.
- If the crusher plant is big enough to keep up, a 2nd excavator can be run to increase feed / throughput.

### 13.3 Part 2 — The Crushing Chain
- Big excavated blocks are fed into the mouth of a primary crusher — usually a JAW crusher — which breaks them into finer material.
- A conveyor-belt system carries the output onward.
- It is then fed into a tertiary crusher — usually an IMPACT crusher — which breaks it into even finer pieces.
- [Note: designer described primary (jaw) -> impact; a secondary stage may exist in larger plants — confirm later.]

### 13.4 Screening — Grizzly / Vibrating Screens & Aggregate Grades
- Grizzly / vibrating screens with multiple levels (e.g. 5–6 layers) sit in the chain, at the output of the tertiary / impact crusher.
- [UNVERIFIED: whether screens also sit at the jaw-crusher output — designer thinks NOT.]
- The screens sift and sort the aggregate into different sizes.
- Output sizing is driven by demand: the market wants particular mm sizes, or a specific company contract specifies required sizes.
- Conveyor belts at the grizzly levels carry the different sized aggregates out and dump them in separate piles by size.
- The lowest grizzly level outputs crusher dust / very fine material (also dumped via belt).
- [Gap-fill (standard practice, inferred): the grizzly / vibrating screens are driven by an electric vibrating motor; the conveyor belts are belt-driven by electric motors; all powered by the plant generator / electricity connection.]

### 13.5 Power & Infrastructure
- Large generators (e.g. 400–500 KVA) are installed.
- Electricity connections and poles must also be set up.

### 13.6 Labor & Site
- Crusher operators are required to run the plant.
- A small shed-type building is built on site to ease logistics.

### 13.7 Output & Loading
- The finished crush (by grade) is loaded into trucks for transport / sale.

### 13.8 How this will be sliced (anti-over-scope)
Full vision above. Session 8 builds ONLY a tiny single-stage crusher: consume raw limestone -> produce crush, with a breakdown/repair mechanic. Deferred to later sessions: the excavator / 2nd excavator, the multi-stage jaw -> impact chain, conveyor belts, grizzly screening & multiple aggregate grades (Session 9), generators / power & electricity, operators / labor, the shed, contracts / market mm-size requirements, and truck loading / transport.

## NOTE
A 2D systems game's strength is DEPTH, not graphics. Factorio and RimWorld look simple and made millions. Pour everything into the simulation depth. The realistic construction knowledge is the unfair advantage — nobody else can build this.
