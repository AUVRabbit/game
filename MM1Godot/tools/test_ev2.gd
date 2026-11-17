extends Node2D

var Router: Variant = null
var State: Variant = null
var DB: Variant = null
var Audio: Variant = null

func _p(msg: String) -> void:
	print(msg)

func _ready() -> void:
	call_deferred("_real_ready")

func _real_ready() -> void:
	Router = get_node("/root/Router")
	State = get_node("/root/State")
	DB = get_node("/root/DB")
	Audio = get_node("/root/Audio")

	_p("=== New game ===")
	State.new_game()
	_p("map_id=%d player=(%d,%d)" % [State.map_id, State.player_x, State.player_y])

	var ms: Variant = load("res://scripts/core/map_scene.gd").new()
	add_child(ms)
	call_deferred("_after", ms)

func _after(ms: Variant) -> void:
	call_deferred("_check_ev2", ms, 0)

func _check_ev2(ms: Variant, frame: int) -> void:
	if frame > 30:
		_p("TIMEOUT - EV2 not triggered after 30 frames")
		_p("EV2 page=%d trigger=%d interp_running=%s message_visible=%s" % [
			ms.events[2].page_index, ms.events[2].trigger(),
			ms.interpreter.running, ms.message.visible])
		get_tree().quit()
		return
	var ev2 = ms.events.get(2)
	if ev2 == null:
		_p("EV2 not found!")
		get_tree().quit()
		return
	var pidx = ev2.page_index
	var trig = ev2.trigger()
	var interp = ms.interpreter.running
	var selfA = State.self_switch(1, 2, "A")
	_p("frame=%d EV2 page=%d trig=%d interp=%s selfA=%s bgm=%s" % [
		frame, pidx, trig, interp, selfA, Audio._current_bgm])
	# If page switched to 1 and selfA=true and interp=false, autorun completed
	if pidx == 1 and selfA and not interp:
		_p("\n=== EV2 autorun COMPLETED SUCCESSFULLY ===")
		_p("BGM playing: %s" % Audio._current_bgm)
		get_tree().quit()
		return
	call_deferred("_check_ev2", ms, frame + 1)
