extends CanvasLayer

## HUD — top-bar readout of cash, resources (G1), plus season + economy event
## banners (G2).
##
## PURE OBSERVER (see GRAPHICS.md §0): it READS GameState / EconomyManager once
## on load to fill in current values, then LISTENS to EventBus for changes. It
## never writes to those autoloads and never calls a component — the simulation
## runs identically with this node deleted.
##
## A CanvasLayer so the bar floats in screen space, ignoring camera zoom/pan.

@onready var _cash_label: Label = %CashLabel
@onready var _season_label: Label = %SeasonLabel
@onready var _banners: VBoxContainer = %Banners

## Active economy event banners, keyed by event id, so each can be removed when
## its matching economic_event_ended arrives (several events can run at once).
var _event_banners: Dictionary = {}

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
	_update_season(EconomyManager.get_current_season())
	# No events are active at startup; the banner area starts empty.

	# 2) Listen for future changes.
	EventBus.cash_changed.connect(_update_cash)
	EventBus.resource_changed.connect(_on_resource_changed)
	EventBus.season_changed.connect(_update_season)
	EventBus.economic_event_started.connect(_on_event_started)
	EventBus.economic_event_ended.connect(_on_event_ended)


func _on_resource_changed(resource_name: String, new_amount: int) -> void:
	if _resource_labels.has(resource_name):
		_update_resource(resource_name, new_amount)


func _update_season(season_name: String) -> void:
	_season_label.text = "Season: %s" % season_name


func _on_event_started(event_id: String, description: String, _effects: Dictionary) -> void:
	# Guard against a duplicate id (shouldn't happen, but keep the dict honest).
	if _event_banners.has(event_id):
		return
	var banner := Label.new()
	banner.text = "⚠ %s" % description
	_banners.add_child(banner)
	_event_banners[event_id] = banner


func _on_event_ended(event_id: String) -> void:
	if not _event_banners.has(event_id):
		return
	_event_banners[event_id].queue_free()
	_event_banners.erase(event_id)


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
