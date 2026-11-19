extends Node

func _ready() -> void:
	var runner := Node.new()
	runner.name = "SmokeRunner"
	runner.process_mode = Node.PROCESS_MODE_ALWAYS
	runner.set_script(load("res://tools/smoke_runner.gd"))
	get_tree().root.add_child.call_deferred(runner)
