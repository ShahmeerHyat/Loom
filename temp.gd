  extends Node

  func _ready():
		EventBus.quarry_strip_progressed.connect(func(c, t): print("strip: ", c, " / ", t, " ft"))
		EventBus.quarry_reached_limestone.connect(func(): print(">> LIMESTONE EXPOSED"))
		EventBus.quarry_limestone_produced.connect(func(a): print("limestone +", a, "  (GameState.limestone = ", GameState.limeston
  ")"))

		var q = preload("res://components/quarry/LimestoneQuarry.gd").new()
		q.overburden_depth = 15.0   # small so it exposes fast
		add_child(q)

		for i in range(7):
				q.work_shift()
