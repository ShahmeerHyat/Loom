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

## NOTE
A 2D systems game's strength is DEPTH, not graphics. Factorio and RimWorld look simple and made millions. Pour everything into the simulation depth. The realistic construction knowledge is the unfair advantage — nobody else can build this.
