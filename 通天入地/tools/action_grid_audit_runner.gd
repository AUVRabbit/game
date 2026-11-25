# ============================================================
# ActionGridAuditRunner — 全职业 × 全动作形变 截图
# 遍历 16 张职业肖像 → 各套 40 种程序化形变 → 逐状态截图
# 最终输出 contact sheet + 每个动作独立 jpg
# 运行：Godot --headless --path . tools/action_grid_audit.tscn
# ============================================================

extends Node

const OUT := "res://docs/ACTION_GRID_2026-11-25/"
const TRAINING_SCENE := "res://scenes/world/training_ground.tscn"

var portrait_paths := [
	"res://assets/portraits/warrior.png",
	"res://assets/portraits/mage.png",
	"res://assets/portraits/runeward.png",
	"res://assets/portraits/priest.png",
	"res://assets/portraits/necromancer.png",
	"res://assets/portraits/bomber.png",
	"res://assets/portraits/mech_pilot.png",
	"res://assets/portraits/engineer.png",
	"res://assets/portraits/bounty_hunter.png",
	"res://assets/portraits/death_knight.png",
	"res://assets/portraits/archer.png",
	"res://assets/portraits/thief.png",
	"res://assets/portraits/qi_adept.png",
	"res://assets/portraits/sniper.png",
	"res://assets/portraits/cyborg.png",
	"res://assets/portraits/hacker.png",
]

var ACTION_CASES: Array = [
	{"enum": "IDLE",           "idx": 0,  "via": "settle"},
	{"enum": "RUN",            "idx": 1,  "via": "settle"},
	{"enum": "ATTACK",         "idx": 2,  "via": "enter_attack"},
	{"enum": "CAST",           "idx": 3,  "via": "enter_cast"},
	{"enum": "DASH",           "idx": 4,  "via": "enter_dash"},
	{"enum": "BLINK",          "idx": 5,  "via": "enter_blink"},
	{"enum": "HURT",           "idx": 6,  "via": "enter_hurt"},
	{"enum": "DEAD",           "idx": 7,  "via": "enter_dead"},
	{"enum": "STAGGER",        "idx": 8,  "via": "settle"},
	{"enum": "RESURRECTING",   "idx": 9,  "via": "settle"},
	{"enum": "SWORD_SWING",    "idx": 10, "via": "enter_sword_swing"},
	{"enum": "BOW_DRAW",       "idx": 11, "via": "enter_bow_draw"},
	{"enum": "THROW_BOMB",     "idx": 12, "via": "enter_throw_bomb"},
	{"enum": "CAST_SPELL",     "idx": 13, "via": "enter_cast_spell"},
	{"enum": "SUMMON_RITUAL",  "idx": 14, "via": "enter_summon_ritual"},
	{"enum": "CHARGING",       "idx": 15, "via": "settle"},
	{"enum": "CAST_FOCUS",     "idx": 16, "via": "settle"},
	{"enum": "BLOCK",          "idx": 17, "via": "settle"},
	{"enum": "READY",          "idx": 18, "via": "settle"},
	{"enum": "CROUCH",         "idx": 19, "via": "settle"},
	{"enum": "WALK_CROUCH",    "idx": 20, "via": "settle"},
	{"enum": "PRONE",          "idx": 21, "via": "settle"},
	{"enum": "LURK",           "idx": 22, "via": "settle"},
	{"enum": "JUMP",           "idx": 23, "via": "enter_jump"},
	{"enum": "JUMP_FALLING",   "idx": 24, "via": "enter_jump"},
	{"enum": "JUMP_LAND",      "idx": 25, "via": "enter_jump"},
	{"enum": "SWIM",           "idx": 26, "via": "settle"},
	{"enum": "CLIMB",          "idx": 27, "via": "settle"},
	{"enum": "ROLL",           "idx": 28, "via": "enter_roll"},
	{"enum": "MOUNTED",        "idx": 29, "via": "settle"},
	{"enum": "FORCE_READY",    "idx": 30, "via": "enter_force_ready"},
	{"enum": "DRINK",          "idx": 31, "via": "settle"},
	{"enum": "CARRY",          "idx": 32, "via": "settle"},
	{"enum": "SIT",            "idx": 33, "via": "settle"},
	{"enum": "TRAP_SET",       "idx": 34, "via": "settle"},
	{"enum": "PORTAL",         "idx": 35, "via": "settle"},
	{"enum": "CELEBRATE",      "idx": 36, "via": "settle"},
	{"enum": "FALL",           "idx": 37, "via": "settle"},
	{"enum": "AOE_SWING",      "idx": 38, "via": "enter_aoe_swing"},
	{"enum": "RAPID_STRIKES",  "idx": 39, "via": "enter_rapid_strikes"},
]

const SA := preload("res://scripts/combat/sprite_anim.gd")

var log_file: FileAccess = null
var checks_total: int = 0
var checks_pass: int = 0
var checks_fail: int = 0

var _level: Node2D = null
var _camera: Camera2D = null
var _host: Node2D = null
var _spr: Sprite2D = null
var _anim: Node = null
var _label: Label = null
var _header: Label = null

# 每个职业做截图时的相机缩放（肖像不同尺寸 + 不同身形都适配）
var _zoom_map: Dictionary = {
	"warrior": 1.45,  "mage": 1.40,  "runeward": 1.45, "priest": 1.40,
	"necromancer": 1.45, "bomber": 1.45, "mech_pilot": 1.50, "engineer": 1.45,
	"bounty_hunter": 1.45, "death_knight": 1.50, "archer": 1.40, "thief": 1.40,
	"qi_adept": 1.40, "sniper": 1.45, "cyborg": 1.50, "hacker": 1.40,
}

var _class_cn := {
	"warrior": "战士", "mage": "法师", "runeward": "咒铠师", "priest": "牧师",
	"necromancer": "亡灵法师", "bomber": "炸弹专家", "mech_pilot": "机甲师", "engineer": "工程师",
	"bounty_hunter": "赏金猎人", "death_knight": "死亡骑士", "archer": "弓箭手", "thief": "小偷",
	"qi_adept": "气宗", "sniper": "狙击手", "cyborg": "义体卫士", "hacker": "黑客",
}

func _ready() -> void:
	call_deferred("_attach")

func _attach() -> void:
	var tree := get_tree()
	# 载入训练场做场景背景
	var packed := load(TRAINING_SCENE)
	if packed == null:
		push_error("[ActionGrid] 训练场场景缺失")
		call_deferred("_quit", 1)
		return
	var scene: Node2D = packed.instantiate()
	tree.root.add_child(scene)
	tree.current_scene = scene
	_level = scene
	_camera = scene.get_node_or_null("Camera2D") as Camera2D
	if _camera == null:
		_camera = Camera2D.new()
		_camera.name = "Camera2D"
		scene.add_child(_camera)
	_camera.make_current()
	# 准备输出目录结构
	var abs_out := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(abs_out)
	log_file = FileAccess.open(abs_out + "audit.log", FileAccess.WRITE)
	call_deferred("_main")

func _log(msg: String) -> void:
	print(msg)
	if log_file != null:
		log_file.store_line(msg)
		log_file.flush()

func _main() -> void:
	_log("===== 全职业 × 全动作形变 截图 =====")
	_log("职业数：%d    动作数：%d    总计 %d 张" % [
		1, ACTION_CASES.size(), ACTION_CASES.size()
	])
	await _wait(0.6)
	# 让相机稳定、让训练场 _ready() 跑完
	await _wait(0.8)
	_camera.position = Vector2(0, -40)
	_camera.zoom = Vector2(1.4, 1.4)
	await _wait(0.2)
	# 创建一个共享的 SpriteAnim（宿主换 sprite 即可）
	_host = Node2D.new()
	_host.name = "ActionAuditHost"
	_host.position = Vector2(0, -40)
	_level.add_child(_host)
	_header = Label.new()
	_header.position = Vector2(-560, -360)
	_header.add_theme_font_size_override("font_size", 28)
	_header.add_theme_color_override("font_color", Color(1.0, 0.96, 0.72))
	_header.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	_level.add_child(_header)
	_label = Label.new()
	_label.position = Vector2(-560, -300)
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	_level.add_child(_label)

	for idx in range(1):
		var path: String = str(portrait_paths[idx])
		var cid: String = path.get_file().get_basename()
		await _run_class(cid, path, idx + 1, portrait_paths.size())
		# 每个职业做完清一次宿主，避免内存累积
		if _anim != null:
			_anim.queue_free()
			_anim = null
		if _spr != null:
			_spr.queue_free()
			_spr = null
		await _wait(0.05)
	_log("===== 完成：%d / %d 动作形变验证通过 =====" % [checks_pass, checks_total])
	call_deferred("_quit", 0)

func _run_class(cid: String, portrait_path: String, num: int, total: int) -> void:
	var tex := load(portrait_path)
	if tex == null:
		_log("[%d/%d] %s SKIP (portrait 缺失)" % [num, total, cid])
		return
	_log("[%d/%d] 职业 %s · 肖像 %dx%d" % [num, total, cid, tex.get_width(), tex.get_height()])
	_header.text = "职业 %d/%d · %s %s" % [num, total, cid, str(_class_cn.get(cid, cid))]
	var cn := str(_class_cn.get(cid, cid))
	# 清除旧 sprite/anim
	for c in _host.get_children():
		c.free()
	_spr = Sprite2D.new()
	_spr.texture = tex
	_spr.scale = Vector2(0.34, 0.34)
	_host.add_child(_spr)
	_anim = SA.new()
	_host.add_child(_anim)
	_anim.call("setup", _spr)
	# 调整相机 zoom 适配不同肖像大小
	var zoom: float = float(_zoom_map.get(cid, 1.4))
	_camera.zoom = Vector2(zoom, zoom)
	await _wait(0.1)
	# 每个动作逐一切换、断言、截图
	for i in range(ACTION_CASES.size()):
		var c: Dictionary = ACTION_CASES[i]
		var enum_name := str(c.get("enum", ""))
		var expected_idx := int(c.get("idx", -1))
		_label.text = "%s · %02d/%02d · %s" % [cn, i + 1, ACTION_CASES.size(), enum_name]
		_anim.call("settle_to", 0, Vector2.RIGHT, 0.0)  # 先复位 idle
		await _wait(0.02)
		_play_action_state(c)
		await _wait(0.12)
		var actual := int(_anim.get("state"))
		var ok := actual == expected_idx
		checks_total += 1
		if ok:
			checks_pass += 1
		else:
			checks_fail += 1
			_log("  FAIL action %02d %s: state=%d expect=%d via=%s" % [
				i + 1, enum_name, actual, expected_idx, str(c.get("via", ""))])
		await _shot("%s/%02d_%s.jpg" % [cid, i + 1, enum_name])
	await _wait(0.05)

func _play_action_state(c: Dictionary) -> void:
	var via := str(c.get("via", "settle"))
	var idx := int(c.get("idx", 0))
	match via:
		"enter_attack":
			_anim.call("enter_attack", "melee", 40.0, 0.4, Vector2(60, 0), Vector2.RIGHT)
		"enter_cast":
			_anim.call("enter_cast", 0.45, Vector2.RIGHT)
		"enter_dash":
			_anim.call("enter_dash")
		"enter_blink":
			_anim.call("enter_blink")
		"enter_hurt":
			_anim.call("enter_hurt", Vector2(-30, 10))
		"enter_dead":
			_anim.call("enter_dead")
		"enter_sword_swing":
			_anim.call("enter_sword_swing", 40.0, 0.4, Vector2.RIGHT)
		"enter_bow_draw":
			_anim.call("enter_bow_draw", 0.45, Vector2.RIGHT)
		"enter_throw_bomb":
			_anim.call("enter_throw_bomb", 0.45, Vector2.RIGHT)
		"enter_cast_spell":
			_anim.call("enter_cast_spell", 0.45, Vector2.RIGHT)
		"enter_summon_ritual":
			_anim.call("enter_summon_ritual", 0.65, Vector2.RIGHT)
		"enter_jump":
			var jump_phase := 6 if str(c.get("enum", "")) == "JUMP" else (7 if str(c.get("enum", "")) == "JUMP_FALLING" else 8)
			_anim.call("enter_jump", jump_phase)
		"enter_roll":
			_anim.call("enter_roll", 1.0)
		"enter_force_ready":
			_anim.call("enter_force_ready", "forge")
		"enter_aoe_swing":
			_anim.call("enter_aoe_swing", 60.0, 0.5, Vector2.RIGHT)
		"enter_rapid_strikes":
			_anim.call("enter_rapid_strikes", 3, 0.18, Vector2.RIGHT)
		_:
			_anim.call("settle_to", idx, Vector2.RIGHT, 0.0)

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout

func _capture(width: int, height: int) -> Image:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	if img.get_width() > width:
		var h := int(round(float(img.get_height()) * float(width) / float(img.get_width())))
		img.resize(width, h)
	return img

func _shot(rel_path: String) -> void:
	var img: Image = await _capture(320, 180)
	var full := ProjectSettings.globalize_path(OUT) + rel_path
	DirAccess.make_dir_recursive_absolute(full.get_base_dir())
	img.save_jpeg(full, 80)

func _quit(code: int) -> void:
	_log("退出 code=%d    checks %d/%d fail=%d" % [code, checks_pass, checks_total, checks_fail])
	get_tree().quit(code)
