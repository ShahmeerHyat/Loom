extends Node

## BlockFactory — the final step of the block-making chain (GAME_PLAN.md
## section 5 item 10, and section 6). Turns crush + cement + sand + water
## into blocks, limited by a per-shift production capacity. This is the
## "and only then does the first block get made" moment from section 6 —
## everything before it (the whole site setup) is deferred.
##
## NOT AUTOPLAY: no timer, never runs by itself. work_shift() is the only
## entry point and the seam where the future labor-deal chain plugs in.
##
## Deferred (all of section 6): site prep / compaction / leveling / floor +
## lenter, buying/repairing machines (new vs used), labor shelter,
## electricity, water bore + tanks, the per-block labor deal, material
## sourcing (local agent vs factory-direct), transport cost/time,
## weighbridge scales & alternate routes, market demand caps (economy /
## market sessions), grade-specific crush recipe, placement, UI.

# --- Recipe per block — standard 1 cement : 3 crush : 6 sand mix (+ water) ---
@export var crush_per_block: int = 3
@export var cement_per_block: int = 1
@export var sand_per_block: int = 6
@export var water_per_block: int = 1

## Most blocks the site can make in one worked shift (the production limit).
##
## PLACEHOLDER VALUE: in the full model this is NOT a fixed dial — it
## emerges from the site's equipment and layout (mixer machine throughput,
## block machine throughput, floor / curing area, crew size — whichever is
## the bottleneck). When the machine-purchase and floor-area sessions land,
## they will compute and set this value; BlockFactory's core logic does not
## change, only the source of the number does.
@export var blocks_per_shift: int = 50


## The ONE entry point. Each call = one worked shift. Makes as many blocks
## as the materials and the per-shift cap allow.
func work_shift() -> void:
	var makeable: int = _max_makeable()
	if makeable <= 0:
		EventBus.blocks_no_input.emit()
		return

	GameState.remove_resource("crush", makeable * crush_per_block)
	GameState.remove_resource("cement", makeable * cement_per_block)
	GameState.remove_resource("sand", makeable * sand_per_block)
	GameState.remove_resource("water", makeable * water_per_block)
	GameState.add_resource("blocks", makeable)
	EventBus.blocks_produced.emit(makeable)


# --- Read helpers (for UI / tests) ---

## How many blocks could be made right now (capped by the per-shift limit
## and by whichever material is scarcest).
func _max_makeable() -> int:
	var limit: int = blocks_per_shift
	limit = mini(limit, _blocks_from_input("crush", crush_per_block))
	limit = mini(limit, _blocks_from_input("cement", cement_per_block))
	limit = mini(limit, _blocks_from_input("sand", sand_per_block))
	limit = mini(limit, _blocks_from_input("water", water_per_block))
	return maxi(0, limit)


## How many blocks the available stock of one input allows. A per_block of
## 0 means that input isn't required, so it doesn't limit production.
func _blocks_from_input(resource: String, per_block: int) -> int:
	if per_block <= 0:
		return blocks_per_shift
	return GameState.get_resource(resource) / per_block  # int division floors
