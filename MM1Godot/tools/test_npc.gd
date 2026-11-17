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

	Router.new_game()
	var ms: Variant = load("res://scripts/core/map_scene.gd").new()
	add_child(ms)
	call_deferred("_after")

func _after() -> void:
	var ms: Variant = get_child(0)
	_p("=== Check ===")
	_p("EV2 page=%d selfA=%s interp=%s" % [
		ms.events[2].page_index, State.self_switch(1, 2, "A"), ms.interpreter.running])

	ms.player.tile_x = 9
	ms.player.tile_y = 5
	ms.player.direction = 8
	ms.player.position = Vector2(9 * 32 + 16, 5 * 32 + 16)

	var fx: int = ms.player.tile_x
	var fy: int = ms.player.tile_y - 1
	var ev: Variant = ms.event_at(fx, fy)
	_p("\n=== EV12 ===")
	_p("Front (%d,%d) ev=%s" % [fx, fy, ev != null])

	ms.player_action()
	call_deferred("_check_step", ms, 0)

func _check_step(ms: Variant, step: int) -> void:
	if step < 10:
		call_deferred("_check_step", ms, step + 1)
		return
	_p("After EV12 action: visible=%s mode=%s chars=%d interp=%s" % [
		ms.message.visible, ms.message._mode, ms.message._char_buf.size(), ms.interpreter.running])

	if ms.message._mode != "none":
		ms.message.finished.emit(0)
		_p("(closed)")

	ms.player.tile_x = 11
	ms.player.tile_y = 5
	ms.player.position = Vector2(11 * 32 + 16, 5 * 32 + 16)
	ms.player_action()
	call_deferred("_check_ev13", ms, 0)

func _check_ev13(ms: Variant, step: int) -> void:
	if step < 10:
		call_deferred("_check_ev13", ms, step + 1)
		return
	_p("\n=== EV13 ===")
	_p("visible=%s chars=%d" % [ms.message.visible, ms.message._char_buf.size()])
	if ms.message._mode != "none":
		ms.message.finished.emit(0)

	ms.player.tile_x = 10
	ms.player.tile_y = 11
	ms.player.position = Vector2(10 * 32 + 16, 11 * 32 + 16)
	ms.player_action()
	call_deferred("_check_ev14", ms, 0)

func _check_ev14(ms: Variant, step: int) -> void:
	if step < 15:
		call_deferred("_check_ev14", ms, step + 1)
		return
	_p("\n=== EV14 shop ===")
	_p("overlay=%s shop_type=%s goods=%d interp=%s" % [
		Router.has_overlay(), State.temp.get("shop_type"),
		len(State.temp.get("shop_goods", [])), ms.interpreter.running])
	Router.close_overlay()

	ms.player.tile_x = 11
	ms.player.tile_y = 11
	ms.player.position = Vector2(11 * 32 + 16, 11 * 32 + 16)
	ms.player_action()
	call_deferred("_check_ev15", ms, 0)

func _check_ev15(ms: Variant, step: int) -> void:
	if step < 15:
		call_deferred("_check_ev15", ms, step + 1)
		return
	_p("\n=== EV15 battle ===")
	_p("overlay=%s in_battle=%s interp=%s" % [
		Router.has_overlay(), State.in_battle, ms.interpreter.running])
	Router.close_overlay()
	get_tree().quit()
