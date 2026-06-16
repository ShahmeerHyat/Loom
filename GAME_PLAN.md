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
Phase 2 — Infrastructure: block machine (new=expensive/reliable vs used=cheap/repair risk); mixer machine same choice; used = find mechanic, parts, downtime; electricity connection (fee, wait); water (drill bore, buy cement rings, stack, plaster, cure); labor shelter. NOTE: these machines + the floor/curing area + crew size TOGETHER determine the block-making throughput (blocks-per-shift) — it is an emergent bottleneck, never a fixed dial.
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

### 11.9 Periodic Internal Safety Survey (designer — added later)
- Roughly every ~7 days a HIRED SURVEYOR carries out an internal survey of the mine to examine its internal state: that labourers are keeping the required safety DIMENSIONS, that VENTILATION is working properly, timber/regs are in order, etc.
- This is a recurring operating cost and a SAFETY-discipline check — it ties directly into the LaborHazard SAFETY dial (section 17): skipping or failing these surveys should let safety drift down and catastrophe risk rise.
- [Deferred] A future mine-operations session models the periodic survey, its cost, and its effect on the safety state. Not part of the Session 5 seed or Session 17 exploration.

### 11.10 Slow Depth Creep Over Time (designer — added later)
- Across long play, the working depth slowly increases (a few feet per day as the seam is followed/deepened). Over years/decades this raises the COST and TIME to bring coal up from the face to the surface.
- To counter rising haulage cost the player eventually UPGRADES: more carts, better/larger haulage engines, rail improvements (ties to 11.6 haulage), etc.
- [Deferred] A future mine-ops session models depth creep and the upgrade treadmill. Not part of the Session 5 seed.

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

## 14. DOMAIN DEEP-DIVE: TRUCKS, TRANSPORT & LOGISTICS (design reference)
> Captured from the designer's direct domain knowledge (includes real figures). Full vision; sliced across sessions (Session 11 = tiny truck seed; weighbridges / road-weather / buyers come later).

### 14.1 Ownership Models
- Whether you own trucks depends on the size of your operation.
- Company-owned trucks: you pay only the driver's wage, fuel, and truck maintenance.
- Hired / third-party trucks: if you haven't bought a truck (or don't plan to), a truck comes to e.g. load your blocks; you pay the loading fee + fuel + the extra charge set by the truck driver / service.

### 14.2 Truck Sizes & Economies of Scale
- Trucks come in multiple sizes; different sizes suit different jobs.
- Bigger trucks cost much less PER UNIT of material (economies of scale).
- Real example (during a high-fuel-price period): ~PKR 32,000 for a 20-ton load vs ~PKR 42,000 for a 40-ton load — double the material for only a little more cost, so far cheaper per ton.

### 14.3 Weighbridges & Supply-Chain Optimization
- Some routes have weighbridges; police may not let a truck carry more than the legal weight.
- Overweight isn't allowed there, which caps throughput — so the whole supply chain must be optimized (load sizes, route choice).

### 14.4 Road Conditions & Weather
- Routes to the mine mouths / salt-mine mouths (where trucks load) are extremely bad — usually no real path, barely a dirt road (only very big companies have better).
- In extreme rain the tyres slip and trucks can't even climb the road to reach the mines. (Ties into the rain / season system.)

### 14.5 Loading & Dispatch Flow
- Trucks load coal, salt, blocks, etc.
- Example: coal is continually brought out; a regular 10-ton truck arrives (e.g. it hauls for a cement factory that needs coal daily, so it buys from us regularly), 10 tons is loaded, the taxes / royalty slip is generated, and the truck departs.
- Payment is received from the truck / load owner — terms vary (sometimes advance, sometimes on delivery / later).

### 14.6 Trucks as a Revenue Source
- The player can also BUY trucks and use them to generate revenue (run loads, serve buyers).

### 14.7 How this will be sliced (anti-over-scope)
Full vision above. Session 11 builds ONLY a tiny truck seed: a truck with a capacity that hauls a material (at a per-trip cost paid in cash) and delivers it into inventory, demonstrating the per-unit economies of scale between sizes. Deferred: ownership models (owned vs hired) & their cost structures, weighbridges, road quality & rain-blocked access, royalty / tax slips, regular buyers & payment terms, trucks-as-revenue, per-site stockpiles, placement, UI.

## 15. DOMAIN DEEP-DIVE: ROAD NETWORK (design reference)
> Captured from the designer's domain context. Full vision; sliced across many sessions (Session 12 = a tiny road-condition seed; the road-BUILDING material chain, the map/zones, and the truck coupling come later). [UNVERIFIED] marks points the designer was unsure about.

### 15.1 The Map & Zones (future — its own sessions)
- The world is a map with distinct zones. A RESIDENTIAL zone holds the player's house and other houses and has GOOD-quality roads.
- Mines, quarries and plants sit in DISTANT, RURAL areas — remote, with dilapidated, barely-there dirt roads (matches GAME_PLAN 14.4: routes to the mine mouths are extremely bad, often no real path).
- Land for buildings / sites can be PURCHASED. (Land acquisition is a separate later session; noted here only as context for where roads live.)

### 15.2 Roads Are a Degrading Asset (not a fixed dial)
- A road has a QUALITY that changes over time — it is never a one-time "build" toggle.
- HEAVY TRUCKS degrade roads through use: more traffic and heavier loads wear the surface down over time.
- RAIN degrades roads. Normal rain is a moderate effect; severe / "bad" rain (e.g. a flood) hits much harder.
- Quality drives TRANSPORTATION: a worse road means slower trips / longer transport times, and below a point it blocks access entirely.

### 15.3 Incline & Rain-Blocked Access (the climb problem)
- Roads leading up to the mine / salt-mine mouths are on an INCLINE and are unpaved dirt.
- In heavy rain the tyres slip and a loaded truck simply cannot climb an inclined dirt road — so transport to/from that site naturally STOPS until conditions improve or the road is good enough.
- A well-built / well-maintained road survives the same weather where a dilapidated dirt one becomes impassable. (Normal rain alone should not fully block; the bad case is heavy rain + incline + a poor dirt surface.)

### 15.4 Building & Maintaining a Road Is a Full Sourced Process (future)
Like everything in Loom, a road is NEVER a simple "build this" button. The full build/maintain chain (each step its own future slice):
- Prepare the SUBBASE; source and lay base materials.
- Source AGGREGATE / gravel — from the player's OWN crusher OR from a wholesaler — and mix to the right RATIOS. [UNVERIFIED: exact mixture ratios / gravel composition.]
- ASPHALT / paving — sourced and laid, same sourcing-and-transport philosophy.
- Finishing touches.
- Materials for each stage come from DIFFERENT places, all sourced, mixed and TRANSPORTED (no free materials).
- WHO HOLDS THE ROAD-CONSTRUCTION CONTRACT matters — quality and cost depend on the contractor. [UNVERIFIED: how road-construction contracting works in detail.]

### 15.5 How this will be sliced (anti-over-scope)
The above is the FULL vision, NOT one session. Session 12 builds ONLY the smallest road-condition seed: a single steep dirt road ("the road up to the mine mouth") with a quality that (a) starts bad, (b) degrades from truck traffic (reacting to the existing `truck_delivered` signal, scaled by load), (c) degrades from rain (moderate on the RAIN season, severe on a `flood` event) and becomes IMPASSABLE when a flood hits a steep, low-quality road, (d) can be repaired by a player-triggered action at a flat placeholder cash cost. It EXPOSES a transport-time multiplier and a passable/access value for the truck to consult later, but does NOT yet rewire `Truck.gd`. Deferred: the map & residential/rural zones, land purchase, the entire road-BUILDING material chain (subbase, aggregate sourcing from crusher vs wholesaler, mixture ratios, asphalt, finishing, transport), road-construction contractors, multiple named road segments / routes, paved vs dirt surface types, and the actual truck speed/access coupling. The flat repair cost is the explicit seam where the sourced build/maintain chain plugs in.

## 16. DOMAIN DEEP-DIVE: LABOR (design reference)
> Captured from the designer's direct domain knowledge. Full vision; sliced across many sessions (Session 13 = a tiny labor-crew + pay-deal seed; Session 14 = labor EVENTS — strikes/disputes/absenteeism/injury). This is what ultimately drives every component's throughput — the `work_shift()`/`run_trip()` entry points exist precisely so the labor chain can plug into them.

### 16.1 Regional / Community Skill Specialization
- Labor comes from different communities / villages, and different areas are KNOWN for different skills (e.g. a particular village is known for good miners). Labor quality and type therefore differ by area.
- Recruiting is tied to where you draw workers from. [Modeled later via a per-crew skill / region; a dedicated recruiting/region session comes later.]

### 16.2 Structure: Mate -> Team
- In mining you hire a MATE, who leads his OWN team of laborers working a gallery. A second mate has a separate team in another gallery, and so on.
- Some laborers have DONKEYS (early haulage — see 11.2/11.6), some don't.
- Crew SIZE varies by site: crusher teams are SMALL (few people needed); mining galleries are larger.
- Block-making needs specific ROLES, not just headcount: one laborer runs the block machine, one runs the mixer / does the mixture; brick kilns have their own distinct laborers.
- Crew size + roles TOGETHER are what really set a site's throughput (the emergent bottleneck of section 6, e.g. the placeholder `blocks_per_shift`).

### 16.3 Negotiated Pay TYPE (the core economic lever)
- PER-UNIT: pay per block produced (block-making) or per amount dug (mining). Cost scales with output — you only pay for what's made.
- DAILY WAGE: external labor hired for a project (e.g. a building job) is paid per day, regardless of output (flat cost / risk on a low-output day).
- MONTHLY STIPEND (fixed staff): site cooks, managers, office staff are on a fixed monthly allowance — paid every period regardless of production (steady overhead).
- The pay type is NEGOTIATED per crew up front; work only starts after the deal (section 6, Phase 3). Advances are sometimes given. [Advances modeled in a later slice.]

### 16.4 Seasonal Availability
- Once a year, crews take a big leave (~3 weeks) to return to their villages — labor is UNAVAILABLE during that window. Ties into the season system.

### 16.5 Unionization
- Labor can be unionized, but this is not very common in this field. [Lower-priority later slice; relates to Session 14 disputes/strikes.]

### 16.6 How this will be sliced (anti-over-scope)
Full vision above. Session 13 builds ONLY the smallest labor seed: a single hired CREW (a mate + a team of laborers under him) with a SKILL factor and a negotiated PAY DEAL of one of three types — PER_UNIT, DAILY, or MONTHLY. It exposes `productive_capacity()` (team_size x output_per_worker x skill) — the value a mine/factory will LATER use as its throughput driver — and a player-triggered `work_shift()` that does the work and charges wages by pay model (per-unit scales with output; daily is flat per team per day; monthly crews aren't charged per shift), plus `pay_period()` to pay monthly fixed staff. It does NOT touch any existing component (mines/crusher/factory keep their placeholder throughput for now). Deferred: village/region recruiting & skill specialization, multiple mates & gallery assignment, donkeys/haulage capability, site-specific crew roles (block-machine vs mixer operator, small crusher teams, kilns), seasonal ~3-week leave/availability, advances & hiring cost, unionization, disputes/strikes/absenteeism/injury (Session 14), and the actual wiring of crews into each component's throughput.

## 17. DOMAIN DEEP-DIVE: LABOR EVENTS / HAZARDS (design reference)
> The RISK layer on top of labor (Session 14 builds the seed). The designer supplied the core truths below; the designer explicitly does NOT know the fine detail of injuries/absenteeism, so most MECHANICS here are inferred standard-practice gap-fills, tagged [Gap-fill (inferred)] and open to revision.

### 17.1 Injury Risk Depends on Work Type (designer)
- Different work carries very different danger. Coal / underground mining is dangerous and injuries are relatively common. Block-making is comparatively safe and easy — low risk.
- So risk is a property of the JOB, not a flat global rate.

### 17.2 Rare Catastrophes from Rules Not Followed (designer)
- Catastrophic events are RARE and tied to SAFETY discipline: e.g. if timber isn't placed at frequent enough intervals (see 11.4), a tunnel can suffer a rock/roof fall and injure workers.
- Following the rules keeps these near-zero; cutting corners makes them spike.

### 17.3 Absenteeism (designer + gap-fill)
- Known (designer): once a year crews take a big ~3-week leave back to their villages (see 16.4) — that whole window is unavailable.
- [Gap-fill (inferred)]: beyond the annual leave, a small random fraction of a crew no-shows on any given shift, reducing how many actually turn up.

### 17.4 Modeling the Risk (gap-fill — inferred standard practice)
- [Gap-fill (inferred)] Two per-job dials: DANGER (how hazardous the work is — coal high, blocks low) and SAFETY (how well rules / timbering are followed — player-influenced later, eventually driven by real timber/tunnel-reg state from 11.4/11.5).
- [Gap-fill (inferred)] Per-shift injury chance scales with danger and with poor safety (~ danger x (1 - safety)). A single worker is typically hurt.
- [Gap-fill (inferred)] Per-shift catastrophe chance scales with danger and rises SHARPLY as safety drops (e.g. squared) — capturing "rules not followed -> collapse". A catastrophe hurts several workers and stops that shift.
- [Gap-fill (inferred)] Injuries and catastrophes cost cash (medical / compensation), catastrophes much more.

### 17.5 Strikes / Disputes (designer, see 16.5)
- Pay-driven disputes: not paying a crew makes them down tools (the `labor_unpaid` seam already emitted by LaborCrew). Unionization (16.5) escalates this but is uncommon.
- [Gap-fill (inferred)] Strikes/disputes are a SEPARATE later slice that extends the pay seam, not part of the Session 14 hazard seed.

### 17.6 How this will be sliced (anti-over-scope)
Full vision above. Session 14 builds ONLY a standalone hazard seed: `LaborHazard` holds a job's DANGER, SAFETY and ABSENTEE_RATE, exposes `injury_chance()` / `accident_chance()` (pure functions, so a coal mine vs a block plant is inspectable), and a `resolve_shift(team_size, ...rolls)` that rolls one shift -> {present, absent, injured, accident, cost, can_work}, charging cash for injuries/accidents. The random draws are injectable (default `randf()`) so the logic is deterministically testable. It does NOT touch LaborCrew or any component (the future mine combines `LaborCrew.work_shift()` + this). Deferred: wiring hazards into real mine/factory shifts, the annual ~3-week leave as a seasonal block, tying SAFETY to real timber/tunnel-reg state (11.4/11.5), injury recovery / worker replacement over time, pay-driven strikes/disputes (extends the `labor_unpaid` seam), injury severity tiers, and insurance. Numbers are placeholders to balance later.

## 18. DOMAIN DEEP-DIVE: SELLING / MARKET (design reference)
> Captured from the designer's direct domain knowledge. Selling differs per material. Full vision; Session 15 builds a tiny spot-sale seed. [UNVERIFIED] / [Gap-fill (inferred)] tag uncertain or inferred points.

### 18.1 Coal — Quality-Driven (designer)
- A coal mine's worth depends on the SEAM QUALITY found at the seam: thickness (a very thin ~10-inch seam may be uneconomic to extract at all) plus chemistry — low SULFUR, VOLATILE MATTER, and GCV (gross calorific value). Poor quality can make extraction infeasible.
- Buyers differ in reliability and standards: CEMENT factories are reliable, consistent, high-volume buyers but want BETTER coal (low sulfur, good GCV); BRICK KILNS are smaller, less reliable buyers.
- Flow: surrounding businesses send trucks (often daily); you load by truck size; a CHIT / slip is cut; government ROYALTY is paid. [UNVERIFIED: royalty paid on the spot vs at month-end — seed pays on the spot.]
- Price nudges on external circumstances: e.g. rain closes brick kilns, so you may slightly discount to keep coal moving — but not so much you break your market. (NOTE: EconomyManager already lowers RAIN-season demand/price for coal & blocks, so selling at the live market price inherits this automatically.)

### 18.2 Crush / Aggregate & Waste By-products (designer)
- Crush is sold for money, same general rules as coal.
- SAND and DUST are effectively WASTE the operator wants gone: they are FREE to buyers, who pay only the loading + transport cost. [So they clear stock rather than earn margin.]
- Sand and dust are priced/measured PER CUBIC FOOT; crush per unit.

### 18.3 Blocks (designer)
- Blocks are sold PER PIECE from a stockpile: a buyer arrives and buys some quantity.

### 18.4 Royalties (designer)
- Government royalty rates DIFFER BY MATERIAL (e.g. coal vs limestone vs gypsum each have their own rate). Modeled as a per-good royalty rate (placeholders until calibrated).
- [Gap-fill (inferred)] Real royalty is levied on the EXTRACTED mineral (coal/limestone/gypsum/salt). For now the seed applies a per-good rate at point of sale; a later slice can move it to extraction/accrual.

### 18.5 Buyers vs Contracts (designer)
- WALK-UP / spot buyers: businesses (cement, kilns, etc.) buy at the prevailing market price, load, and go.
- ANNUAL CONTRACTS: you can sign annual supply deals with projects / big companies — sometimes won by competitive BIDDING against rivals. These are large and lucrative, and apply to future ventures/materials too. (Relates to Session 16 Other Buyers and section 22 Construction Contracts.)

### 18.6 How this will be sliced (anti-over-scope)
Full vision above. Session 15 builds ONLY a spot-sale seed: a `Market` component that sells the three goods EconomyManager already prices (coal / crush / blocks) at the LIVE market price, deducts a PER-MATERIAL government royalty, removes the resource and adds the net cash. It stays decoupled by caching prices from the EventBus `price_changed` signal (never calling EconomyManager directly). It exposes `quote()` (preview) and `sell()`, emitting `good_sold` (the chit) or `sale_failed`. Deferred: coal seam QUALITY (thickness/sulfur/GCV) & extraction feasibility; buyer TYPES (cement vs kiln), reliability, daily truck arrivals & quality requirements; the FREE sand/dust by-product (loading+transport only) & per-cubic-foot pricing; selling individual crush GRADES (the grizzly's 20mm/13mm/6mm/dust); the blocks-per-piece nuance (seed uses the per-unit price); ANNUAL CONTRACTS & competitive bidding (Session 16 / section 22); the manual discount lever; and royalty timing/accrual (seed pays on the spot). Numbers are placeholders.

## 19. DOMAIN DEEP-DIVE: BUYERS & COMPETITION (design reference)
> Captured from the designer's direct domain knowledge. The DEMAND side of selling (section 18.5), built out in Session 16. [UNVERIFIED]/[Gap-fill (inferred)] tag uncertain/inferred points.

### 19.1 Buyers Have Per-Buyer Quality Requirements (designer)
- Different buyers demand different quality of the SAME material, and reject material below their bar:
  - Coal: brick kilns have LOW quality requirements; cement factories want HIGHER quality, especially LOW SULFUR (so their plant/materials don't corrode).
  - Crush: normal construction mix accepts regular aggregate; a buyer like a SODA-ASH plant needs very PURE aggregate.
- So who you can sell to depends on the quality your mine/crusher produces (quality source deferred — see 18.6).

### 19.2 Who the Buyers Are (designer)
- Many entities buy: companies, MIDDLEMEN, and AGENTS.
- Haggling is minor — essentially fair market value, small band at most. [Gap-fill (inferred): model a small negotiation band later.]

### 19.3 Deal Shapes: Contracts vs Individuals (designer)
- LONG-TERM CONTRACTS are usually made with companies: when a contract is signed the PRICE IS LOCKED until the contract ends, for a committed quantity over its life.
- INDIVIDUAL buyers are one-time or a few recurrent purchases at the prevailing (≈ market) price.

### 19.4 Competition (designer)
- It's capitalism — RIVALS always exist in the free market and compete for buyers/business.
- EXCLUSIVITY: once a contract is signed, there is NO competitor for that contract's demand until it ends. The open free market (individual buyers) stays contested.
- [Gap-fill (inferred)] Competitive BIDDING (you bid a price vs rivals to win a contract) is a later slice; the seed models a contract's exclusivity/lifecycle but not AI rivals winning/losing bids.

### 19.5 Payment Terms (designer)
- Payments come in multiple forms: ADVANCE, on-the-spot / on-delivery, etc. [UNVERIFIED: the full set and how common each is.]
- [Gap-fill (inferred)] Advance = part/all paid up front before delivery; on-delivery = paid when goods arrive. Timing/risk modeled in a later slice (seed pays on delivery).

### 19.6 How this will be sliced (anti-over-scope)
Full vision above. Session 16 builds ONLY a standalone `Buyer` seed: one buyer with a `material`, a `min_quality` bar, an agreed `unit_price`, and a `kind` (INDIVIDUAL spot vs CONTRACT). `evaluate(quality, amount)` previews and rejects under-quality / already-fulfilled / empty offers; a CONTRACT caps the accepted amount at its committed `contract_remaining` and locks its price, an INDIVIDUAL takes the one-off offer at its price. `deliver(quality, amount)` fulfills: removes the resource from GameState and pays cash, decrementing a contract and emitting `contract_fulfilled` when done; rejects cleanly on under-quality / fulfilled / insufficient stock. Since materials don't carry quality yet, the offered QUALITY is passed in (the seam where mine seam-quality / crusher purity plug in later). Deferred: the quality SOURCE (sulfur/GCV/purity); payment-terms TIMING (advance vs on-delivery); the haggle band; rival competitive BIDDING for contracts; middlemen/agents; a marketplace of many buyers; and ROYALTY on direct-buyer sales (seed pays gross — unified with Market's per-material royalty in a later integration). Numbers are placeholders.

## 20. DOMAIN DEEP-DIVE: EXPLORATION & SITE SURVEY (design reference)
> Captured from the designer's direct domain knowledge. How new MINE/QUARRY sites are found and assessed before committing. Full vision; Session 17 builds the assessment seed. [Gap-fill (inferred)] tags inferred mechanics.

### 20.1 Scope (designer)
- Exploration applies to MINES & QUARRIES (coal, limestone, salt) — NOT to block-making sites or building construction (those are chosen/placed, not prospected).

### 20.2 Finding a Site (designer)
- Several routes: visit a GOVERNMENT office and obtain government MAPS showing LEASABLE BLOCKS available for sale / AUCTION; and/or HIRE SURVEYORS to find prospects.
- (The actual lease/acquisition and auction live in the Lease system — section 5 #19.)

### 20.3 Investigating a Block (designer)
- Once you're interested in a block, you do DRILL BORE tests / test holes at different spots to learn what's underground.
- Done by a SPECIALIST (or your own company person, but usually a specialist).

### 20.4 Sampling & Lab Results (designer)
- You take coal / limestone SAMPLES and send them to a LAB; the results reveal QUALITY.
- A limestone quarry's worth depends on the limestone QUALITY, exactly as a coal mine depends on coal quality (sulfur/GCV etc., section 18.1).

### 20.5 Progressive Confidence (gap-fill — inferred)
- [Gap-fill (inferred)] More test bores at different spots = a clearer, tighter picture of seam depth and quality; the lab sample confirms the material's chemistry/quality. Early on the estimate is a wide range; investigation narrows it.

### 20.6 How this will be sliced (anti-over-scope)
Full vision above. Session 17 builds ONLY a `ProspectSite` assessment seed: a candidate block with HIDDEN true attributes (material, seam depth, quality) the player can't see until they survey. `drill_bore()` costs cash per bore, raises a CONFIDENCE that narrows the estimated depth & quality RANGES; `lab_sample()` costs cash and CONFIRMS the exact quality (requires at least one bore first). `quality_estimate()` / `depth_estimate()` return low–high ranges that tighten with confidence (unknown before any bore; quality exact after the lab). Estimates are unbiased (centered on truth, band narrows) for a clean deterministic model. THIS is where the `quality` value that Market (18.6) and Buyer (19.6) await is finally produced. Deferred: the discovery channel (gov maps / auction listings) and the LEASE / acquisition itself (section 5 #19); the surveyor as a hireable person; MISLEADING / biased estimates; seam-THICKNESS & automatic feasibility calls; world-map spatial placement; salt-prospecting specifics; and wiring a surveyed site's quality into a live mine. Numbers are placeholders.

## 21. DOMAIN DEEP-DIVE: LEASE & ACQUISITION (design reference)
> A few designer truths (the rest is gap-fill — the designer said to fill in the gaps). How a leasable block becomes yours. Builds on 11.1 and 20.2. Session 19 builds the acquisition seed. [Gap-fill (inferred)] tags inferred mechanics.

### 21.1 What a Lease Is (designer + 11.1)
- Leases differ by material and carry an AREA and a TOTAL PRICE (e.g. a salt lease has its area and price). The GOVERNMENT OFFICE holds the authority to grant them.
- A lease is granted after a WAIT; the TERM varies by material (e.g. coal 10–30 years). It ties you to ONE material and ONE specific block — you may only extract what it's granted for (11.1).
- Government maps (20.2) list leasable blocks available for sale / auction.

### 21.2 Acquisition Paths (designer + gap-fill)
- AUCTION: some blocks are put up for auction (designer). [Gap-fill (inferred)] You bid against rivals; the highest bid over the reserve wins and pays its bid.
- APPLICATION: [Gap-fill (inferred)] other blocks are taken by applying at the government office and paying the set price, then waiting out government processing before it's granted.

### 21.3 Deferred Detail (gap-fill / later sessions)
- [Gap-fill (inferred)] Corruption / BRIBES to speed approval, with raid/fine risk — that's the Corruption system (section 5 #20, section 3.5).
- [Gap-fill (inferred)] Lease EXPIRY and RENEWAL near term end.
- [Gap-fill (inferred)] Rival COMPANIES acquiring leases dynamically (competition, 3.5); multi-round / multi-bidder auctions.

### 21.4 How this will be sliced (anti-over-scope)
Full vision above. Session 19 builds ONLY a standalone `Lease` acquisition seed: one leasable block with a `material`, `area_acres`, `term_years`, and a `method` (APPLICATION or AUCTION). APPLICATION: `apply()` pays the set price -> PENDING; `advance_days(n)` counts down government processing (the TimeManager seam) -> GRANTED. AUCTION: `bid(amount)` (must clear the reserve) records your bid and whether you lead the fixed `rival_top_bid`; `close_auction()` grants it (paying your bid) if you outbid the rival, else LOST. Once GRANTED it's owned for the term, tied to one material. Deferred: corruption/bribes & raids (Session 20); lease expiry/renewal; dynamic rival companies & multi-bidder auctions; a real TimeManager driving the wait; the government-office UI; and wiring a granted lease to a surveyed ProspectSite and to permitting/spawning the actual mine (enforcing the one-material rule). Numbers are placeholders.

## 22. DOMAIN DEEP-DIVE: CORRUPTION & BRIBERY (design reference)
> Designer truths below; risk/exposure mechanics are gap-fill. A CROSS-DOMAIN system — not mining-only (quarries, block sites, weighbridges, government offices all apply). "Just the cost of doing business." [Gap-fill (inferred)] tags inferred mechanics.

### 22.1 Who Gets Bribed (designer)
- Many officials can be bribed: MINE INSPECTORS (who visit regularly), GOVERNMENT / LEASE officials (to get or use leases faster), WEIGHBRIDGE operators (to wave overloaded trucks through), and others.
- It applies across the whole business — mines, QUARRIES, BLOCK sites, etc. — not just mining.

### 22.2 Two Shapes of Bribe (designer)
- ONE-TIME: a single favor — let an overloaded truck pass, expedite a lease, etc. Pay, get the favor, done.
- ONGOING / REGULAR: discreet recurring "ENVELOPES" / "donations" to officials who visit regularly (inspectors). It's an unspoken RELATIONSHIP — they then "look the other way." Everything goes unsaid; you go to them.

### 22.3 Effects (designer)
- Make things FASTER (e.g. speed a lease approval), let VIOLATIONS slide (overload, safety), get inspectors to OVERLOOK problems.

### 22.4 Risk & Relationship (gap-fill — inferred)
- [Gap-fill (inferred)] A bribe carries a chance of being EXPOSED -> raid / FINE (ties to 3.5). One-off bribes to a cold/stranger official are riskier and pricier; a cultivated ONGOING relationship (trust) makes future favors CHEAPER and SAFER.

### 22.5 How this will be sliced (anti-over-scope)
Full vision above. Session 20 builds ONLY a standalone, role-agnostic `Official` seed: an official (free-string `role`) with an `expected_bribe`, a `base_catch_chance`, and a `trust` relationship level. `offer_bribe(amount, catch_roll)` grants a favor if the offer clears `required_bribe()`, after paying — but rolls for EXPOSURE; if caught it pays a FINE (a multiple of the bribe) and the favor fails. `pay_retainer(amount)` builds `trust`, which LOWERS both `required_bribe()` and `catch_chance()` (a regular relationship is cheaper & safer than a cold one-off). The catch roll is injectable (default randf()) for deterministic tests. Effects are ABSTRACT here (the call just reports whether the favor was granted). Deferred: wiring favors into Lease (shorten the wait), weighbridge (pass an overload), and inspectors (overlook a failed safety survey -> keeps LaborHazard.safety from biting); raid ESCALATION beyond a fine; accumulating HEAT / reputation across many bribes; officials being transferred; and UI/flavor. Numbers are placeholders.

## 23. DOMAIN DEEP-DIVE: TOWN GROWTH (design reference)
> Captured from the designer. You operate in a town/city/village that grows ORGANICALLY as you serve it; growth feeds the demand->sales->revenue loop. Session 21 builds the seed.

### 23.1 The Growth Loop (designer)
- You start a business in a town. As the town GROWS it needs MORE — coal for energy, stone/crush & aggregate for works, blocks for construction.
- More demand -> more sales -> more revenue -> funds more activity, which grows the town further. Organic, self-reinforcing growth.
- A bigger, more developed town also brings more OPPORTUNITY to find/hire BETTER labour (ties to section 16).

### 23.2 How this will be sliced (anti-over-scope)
Full vision above. Session 21 builds ONLY a `Town` seed: a town with a `population`, per-capita `needs` (coal/crush/blocks), the `prices` it pays, and per-good `growth_weight` (construction grows it more than energy). `demand_for(good)` scales with population. `supply(good, amount)` consumes up to current demand, PAYS cash (revenue), and adds GROWTH; crossing a threshold raises population (`town_grew`), which raises all demand (and each further step costs more growth). Fails cleanly on a good it doesn't need / not enough stock. Deferred: better-labour-from-growth wiring; routing town demand into Market/Buyer; per-period satiation (the seed caps each call at current demand but doesn't track a period); multiple towns / districts; the town consuming services not just goods; and any spatial/world map. Numbers are placeholders.

## 24. DOMAIN DEEP-DIVE: POWER / ENERGY (design reference — FUTURE, not yet built)
> Captured from the designer for future sessions. How sites are powered; ties to 13.5 (generators / electricity for the crusher plant).
- GENERATORS: large gensets (e.g. 400–500 KVA, 13.5) have a capital cost plus ongoing FUEL / consumption; running cost scales with the plant's draw.
- GRID: electricity connection + poles (13.5) — a connection fee and wait, then metered consumption.
- SOLAR: a capital-heavy alternative — buy panel plates, inverters, and pay an install company; needs LAND AREA for the panels. Once installed it LOWERS operating cost (higher profit) where it fits the load — e.g. a crusher's daytime draw; less suited to coal operations.
- The choice (genset vs grid vs solar) is a capex-vs-opex tradeoff per site.
- [Deferred] Each of these is its own future session (power as an input cost to crusher/factory/etc., the solar capex build, land for panels). NOT built yet — recorded so it isn't lost.

## 25. DOMAIN DEEP-DIVE: LAND & PROPERTY DEVELOPMENT (design reference — FUTURE, not yet built)
> Captured from the designer. IMPORTANT: Loom is NOT just a mining game — property/construction ventures are a planned pillar. For future sessions.
- LAND & PLACES: land area is available to BUY or RENT; you can also rent an existing building/place. (Distinct from mining LEASES in section 21 — this is ordinary property.)
- CONSTRUCTION / DEVELOPMENT: after acquiring land you can CONSTRUCT buildings on it — apartments, complexes, or other building types. Choose the building SIZE and how many/what sizes, work to a BUDGET PER SQUARE FOOT, and set a SELLING PRICE per unit; sell units / make complexes for profit. This consumes your own materials (blocks/crush/cement etc.) and labour (daily-wage crews, section 16.3) — the same sourced, never-one-click philosophy.
- This connects the whole supply chain to an end market: your blocks/aggregate feed your OWN developments and the growing town (section 23).
- [Deferred] A multi-session venture of its own (land acquisition, the build process per phase like section 6, unit sales, financing). NOT built yet — recorded so it isn't lost.

## NOTE
A 2D systems game's strength is DEPTH, not graphics. Factorio and RimWorld look simple and made millions. Pour everything into the simulation depth. The realistic construction knowledge is the unfair advantage — nobody else can build this.
