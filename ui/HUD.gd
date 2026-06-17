extends CanvasLayer

## HUD — top-bar readout of cash and resources (Graphics slice G1).
##
## PURE OBSERVER (see GRAPHICS.md §0): it READS GameState once on load to fill
## in current values, then LISTENS to EventBus for changes. It never writes to
## GameState and never calls a component — the simulation runs identically with
## this node deleted.
##
## A CanvasLayer so the bar floats in screen space, ignoring camera zoom/pan.

@onready var _cash_label: Label = %CashLabel

## Resource key -> its Label. Keys match GameState's tracked resources.
@onready var _resource_labels: Dictionary = {
	"coal": %CoalLabel,
	"limestone": %LimestoneLabel,
	"salt": %SaltLabel,
	"crush": %CrushLabel,
	"blocks": %BlocksLabel,
	"cement": %CementLabel,
	"sand": %SandLabel,
	"water": %WaterLabel,
}


func _ready() -> void:
	# 1) Sync to current state. The autoloads' startup emits fired before this
	# scene existed, so read the live values directly rather than waiting for
	# a signal that already came and went.
	_update_cash(GameState.cash)
	for res_name in _resource_labels:
		_update_resource(res_name, GameState.get_resource(res_name))

	# 2) Listen for future changes.
	EventBus.cash_changed.connect(_update_cash)
	EventBus.resource_changed.connect(_on_resource_changed)


func _on_resource_changed(resource_name: String, new_amount: int) -> void:
	if _resource_labels.has(resource_name):
		_update_resource(resource_name, new_amount)


func _update_cash(new_amount: int) -> void:
	_cash_label.text = "Cash: $%s" % _with_commas(new_amount)


func _update_resource(resource_name: String, new_amount: int) -> void:
	var label: Label = _resource_labels[resource_name]
	label.text = "%s: %s" % [resource_name.capitalize(), new_amount]


## Format an int with thousands separators (10000 -> "10,000").
func _with_commas(n: int) -> String:
	var s: String = str(n)
	var out: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out
