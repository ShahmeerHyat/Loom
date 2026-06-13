extends Control

## StartMenu — the game's entry screen (GAME_PLAN.md section 5, item 4).
##
## The player names their company and starts. On start it hands the name
## to GameState (the single source of truth) and loads the world scene.
## It does not reach into any other component.

const WORLD_SCENE: String = "res://world/Main.tscn"

@onready var _name_edit: LineEdit = %CompanyNameEdit
@onready var _cash_label: Label = %CashLabel
@onready var _start_button: Button = %StartButton
@onready var _error_label: Label = %ErrorLabel


func _ready() -> void:
	_cash_label.text = "Starting Cash: $%s" % _with_commas(GameState.STARTING_CASH)
	_error_label.text = ""
	_start_button.pressed.connect(_on_start_pressed)
	_name_edit.text_submitted.connect(_on_name_submitted)
	_name_edit.grab_focus()


func _on_name_submitted(_text: String) -> void:
	_on_start_pressed()


func _on_start_pressed() -> void:
	var company: String = _name_edit.text.strip_edges()
	if company.is_empty():
		_error_label.text = "Please enter a company name."
		return
	GameState.start_company(company)
	get_tree().change_scene_to_file(WORLD_SCENE)


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
