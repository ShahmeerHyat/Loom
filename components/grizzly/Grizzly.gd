extends Node

## Grizzly — vibrating-screen sorter (GAME_PLAN.md section 5 item 9, and
## section 13.4). Consumes generic crush and screens it into graded crush
## by size (e.g. 20mm / 13mm / 6mm / dust), stored in GameState.crush_grades.
##
## NOT AUTOPLAY: no timer, never runs by itself. work_shift() is the only
## entry point and the seam where the future operator/labor chain plugs in.
## (In reality the screen is driven by an electric vibrating motor and the
## conveyors by belt motors off the plant generator — power is deferred.)
##
## Deferred (GAME_PLAN 13.8): real multi-level screen decks, conveyors,
## power/generator, operators/labor, demand/contract-driven grade targets,
## trucks/loading, placement, UI. Grade split here is a fixed ratio for now.

# --- Tuning (safe to tweak) ---
## Generic crush consumed and screened per shift.
@export var crush_per_shift: int = 20

## Output split by grade. Keys are size labels, values are the fraction of
## the batch that ends up at that grade. Insertion order matters: the LAST
## grade absorbs any rounding remainder (so it is the finest / "dust").
@export var grade_split: Dictionary = {
	"20mm": 0.35,
	"13mm": 0.30,
	"6mm": 0.20,
	"dust": 0.15,
}


## The ONE entry point. Each call = one screened shift. Needs enough crush
## to screen; splits it into grades and banks them in GameState.
func work_shift() -> void:
	if GameState.get_resource("crush") < crush_per_shift:
		EventBus.grizzly_no_input.emit()
		return

	GameState.remove_resource("crush", crush_per_shift)
	EventBus.grizzly_screened.emit(crush_per_shift)

	var portions: Dictionary = _split(crush_per_shift)
	for grade in portions:
		GameState.add_crush_grade(grade, portions[grade])


# --- Internal ---

## Split a batch into integer amounts per grade. Conserves the total
## exactly by dumping any rounding remainder into the last grade (dust).
func _split(total: int) -> Dictionary:
	var result: Dictionary = {}
	var allocated: int = 0
	var keys: Array = grade_split.keys()

	for i in range(keys.size()):
		var grade: String = keys[i]
		if i == keys.size() - 1:
			result[grade] = total - allocated  # remainder -> finest grade
		else:
			var amount: int = int(floor(total * float(grade_split[grade])))
			result[grade] = amount
			allocated += amount

	return result
