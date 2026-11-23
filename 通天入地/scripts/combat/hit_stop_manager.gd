# ============================================================
# HitStopManager — 命中停顿（D3 风格 hit stop）
# 命中瞬间整个游戏暂停一小段时间，制造"打中了！"的沉重感
# API: HitStop.hit(0.06, 2.0)    # 停 60ms，强度 2.0（影响震屏）
# ============================================================

extends Node
class_name HitStopManager

var _active := false
var _remaining: float = 0.0
var _accumulated: float = 0.0
var _current_intensity: float = 1.0
var _scene_tree: SceneTree = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func hit(duration: float = 0.06, intensity: float = 1.0) -> void:
	# 多次命中叠加上限，避免无限停
	_accumulated = minf(_accumulated + duration, 0.14)
	_current_intensity = maxf(_current_intensity, intensity)
	if not _active:
		_active = true
		_remaining = _accumulated
		_accumulated = 0.0
		_scene_tree = get_tree()
		if _scene_tree != null:
			_scene_tree.paused = true

func _process(delta: float) -> void:
	if not _active:
		return
	_remaining -= delta
	if _remaining <= 0.0:
		# 有叠加？继续停
		if _accumulated > 0.0:
			_remaining = _accumulated
			_accumulated = 0.0
			return
		_active = false
		var recovered_intensity := _current_intensity
		_current_intensity = 1.0
		if _scene_tree != null:
			_scene_tree.paused = false
		# 停顿结束时触发震屏（把"打中了"的感觉延续一下）
		if ScreenShake and ScreenShake.has_method("shake"):
			ScreenShake.shake(3.0 * recovered_intensity, 0.08 * recovered_intensity, 60.0 * recovered_intensity)

func is_active() -> bool:
	return _active
