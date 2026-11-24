# ============================================================
# ActionController — 统一动作系统控制器（全局唯一接口）
#
# 架构:
#   每个"有动作的对象"（Player / Enemy / Minion / NPC）都挂一个 ActionController。
#   ActionController 管理 3 层：
#     Layer 1: ActionState 状态机（当前在做什么）
#     Layer 2: ActionProfile 能力集（这个对象能做什么）
#     Layer 3: SpriteAnim 形变执行层（程序化形变 + 帧动画切换）
#
#   灵魂控制 (SoulBind)：切换对象形态时，只换 profile + sheet_id，
#   同一个 controller 继续跑，动作平滑过渡到新形态的同款状态。
#
# 扩展: 加新动作 → 加 enum 值 + 在 ActionProfile 里设 can_do=true +
#        在 SpriteAnim._process 里加 match 分支。
#        加新对象类型 → 在 ActionProfileRegistry 注册 profile + sheet_id。
#
# 用法:
#   var ctrl := ActionController.new()
#   ctrl.bind(character_body, profile_id="player_warrior", sheet_id="player_warrior")
#   ctrl.play("idle")          # 任意 ActionState 的 string 名
#   ctrl.soul_bind_to("enemy_slime")  # 切换形态（灵魂控制）
#
# 状态流转:
#   IDLE ←→ WALK ←→ RUN
#   IDLE → CROUCH → WALK_CROUCH
#   IDLE → PRONE
#   IDLE → LURK (潜伏)
#   IDLE → ATTACK_MELEE / ATTACK_BOW / ATTACK_THROW
#   IDLE → CAST_SPELL / SUMMON_RITUAL / FORGE / DIALOG / SEARCH
#   任意 → HURT / DEAD
# ============================================================

extends Node
class_name ActionController

# -------------------- ActionState 枚举 --------------------
enum ActionState {
	# --- 基础循环 ---
	IDLE, WALK, RUN,

	# --- 低姿态（战术）---
	CROUCH, WALK_CROUCH, PRONE, LURK,

	# --- 移动特殊 ---
	JUMP, JUMP_FALLING, JUMP_LAND,     # 跳跃三件套
	SWIM, SWIM_IDLE,                    # 水下
	CLIMB,                               # 攀爬（绳/梯）
	ROLL,                                # 翻滚闪避
	MOUNTED, DISMOUNT,                   # 骑乘上下

	# --- 战斗动作（每种独立曲线）---
	ATTACK_MELEE,
	ATTACK_BOW,
	ATTACK_THROW,
	ATTACK_SPELL,
	ATTACK_SUMMON,
	ATTACK_CHAIN,
	ATTACK_UNARMED,                     # 徒手（拳/爪）
	ATTACK_RAPID,                        # 快速连击（弓手连射/战士乱斩）
	ATTACK_AOE,                          # 范围重斩（横扫/冲击波）

	# --- 蓄力/专注 ---
	CHARGING,                            # 按住蓄力（body 压缩 + 能量汇聚）
	CAST_FOCUS,                          # 长施法前摇（双手高举 + 光环生成）

	# --- 防御 ---
	BLOCK,                               # 举盾/格挡（身体微侧 + 盾在前）
	READY,                               # 武器举起重试（不动但有呼吸）

	# --- 冲刺/闪现 ---
	DASH, BLINK,

	# --- 受击/死亡/复活 ---
	HURT, STAGGER, DEAD, RESURRECTING,

	# --- 交互场景化 ---
	DIALOG, FORGE, SEARCH, PICK_UP, OPEN_DOOR,
	DRINK,                               # 喝药水/吃食物
	CARRY,                               # 搬东西/抬尸体
	SIT,                                 # 坐下
	TRAP_SET,                            # 放陷阱
	PORTAL,                              # 传送仪式

	# --- 胜利 ---
	Celebrate, FALL,
}

# -------------------- 单例接口 --------------------
var host: Node2D = null
var state: ActionState = ActionState.IDLE
var facing: Vector2 = Vector2.DOWN
var profile: Dictionary = {}  # 当前 profile
var _anim: SpriteAnim = null
var _frame_anim: AnimatedSprite2D = null
var _sheet_id: String = ""
var _frame_w: int = 96
var _frame_h: int = 96

func bind(owner: Node2D, profile_id: String, sheet_id: String = "", frame_w: int = 96, frame_h: int = 96) -> void:
	host = owner
	_anim = SpriteAnim.new()
	_anim.name = "Anim"
	_anim.setup(owner)
	add_child(_anim)
	# 注册 profile
	profile = ActionProfileRegistry.get(profile_id)
	_sheet_id = sheet_id
	_frame_w = frame_w
	_frame_h = frame_h
	# 尝试挂帧动画层
	_try_attach_frames()

func _try_attach_frames() -> void:
	if host == null:
		return
	if _sheet_id == "":
		return
	var actions := ["idle", "walk", "attack", "hit"]
	var counts := [4, 4, 3, 2]
	var fps_list := [6, 10, 12, 14]
	var frames := SpriteFramesBuilder.from_asset_id(_sheet_id, _frame_w, _frame_h, actions, counts, fps_list)
	if frames.get_animation_names().size() == 0:
		return
	_frame_anim = AnimatedSprite2D.new()
	_frame_anim.name = "FrameAnim"
	_frame_anim.sprite_frames = frames
	_frame_anim.animation = "idle"
	_frame_anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	host.add_child(_frame_anim)

# -------------------- 动作查询 --------------------
func can_do(action_name: String) -> bool:
	return bool(profile.get("can_" + action_name, false))

func list_available() -> Array[String]:
	var out: Array[String] = []
	for k in profile.keys():
		if k.begins_with("can_") and bool(profile[k]):
			out.append(k.substr(4))
	return out

# -------------------- 动作切换 --------------------
func play(action_name: String, params: Dictionary = {}) -> void:
	var target := _state_from_name(action_name)
	if target == state and target != ActionState.IDLE:
		return
	if not can_do(action_name):
		push_warning("[ActionController] %s 不能做 %s" % [profile.get("id", "?"), action_name])
		return
	state = target
	match target:
		# --- 基础循环 ---
		ActionState.IDLE:  _anim.settle_to(SpriteAnim.AnimState.IDLE, facing)
		ActionState.WALK:  _anim.settle_to(SpriteAnim.AnimState.RUN, facing)
		ActionState.RUN:   _anim.settle_to(SpriteAnim.AnimState.RUN, facing)
		# --- 低姿态 ---
		ActionState.CROUCH:     _anim.settle_to(SpriteAnim.AnimState.CROUCH, facing)
		ActionState.WALK_CROUCH: _anim.settle_to(SpriteAnim.AnimState.WALK_CROUCH, facing)
		ActionState.PRONE:      _anim.settle_to(SpriteAnim.AnimState.PRONE, facing)
		ActionState.LURK:       _anim.settle_to(SpriteAnim.AnimState.LURK, facing)
		# --- 移动特殊 ---
		ActionState.JUMP, ActionState.JUMP_FALLING, ActionState.JUMP_LAND:
			_anim.enter_jump(target)
		ActionState.SWIM, ActionState.SWIM_IDLE:
			_anim.settle_to(SpriteAnim.AnimState.SWIM, facing)
		ActionState.CLIMB:  _anim.settle_to(SpriteAnim.AnimState.CLIMB, facing)
		ActionState.ROLL:   _anim.enter_roll(float(params.get("direction", facing.x)))
		ActionState.MOUNTED, ActionState.DISMOUNT:
			_anim.settle_to(SpriteAnim.AnimState.MOUNTED, facing)
		# --- 战斗动作（每种独立曲线）---
		ActionState.ATTACK_MELEE:
			_anim.enter_sword_swing(float(params.get("range", 40)), float(params.get("duration", 0.35)), facing)
		ActionState.ATTACK_BOW:
			_anim.enter_bow_draw(float(params.get("duration", 0.42)), facing)
		ActionState.ATTACK_THROW:
			_anim.enter_throw_bomb(float(params.get("duration", 0.45)), facing)
		ActionState.ATTACK_SPELL:
			_anim.enter_cast_spell(float(params.get("duration", 0.45)), facing)
		ActionState.ATTACK_SUMMON:
			_anim.enter_summon_ritual(float(params.get("duration", 0.65)), facing)
		ActionState.ATTACK_CHAIN:
			_anim.enter_cast_spell(float(params.get("duration", 0.35)), facing)
		ActionState.ATTACK_UNARMED:
			_anim.enter_sword_swing(float(params.get("range", 28)), float(params.get("duration", 0.28)), facing)
		ActionState.ATTACK_RAPID:
			_anim.enter_rapid_strikes(int(params.get("count", 3)), float(params.get("duration_each", 0.18)), facing)
		ActionState.ATTACK_AOE:
			_anim.enter_aoe_swing(float(params.get("radius", 60)), float(params.get("duration", 0.5)), facing)
		# --- 蓄力/专注 ---
		ActionState.CHARGING:
			_anim.settle_to(SpriteAnim.AnimState.CHARGING, facing)
		ActionState.CAST_FOCUS:
			_anim.settle_to(SpriteAnim.AnimState.CAST_FOCUS, facing)
		# --- 防御 ---
		ActionState.BLOCK:
			_anim.settle_to(SpriteAnim.AnimState.BLOCK, facing)
		ActionState.READY:
			_anim.settle_to(SpriteAnim.AnimState.READY, facing)
		# --- 冲刺/闪现 ---
		ActionState.DASH:  _anim.enter_dash()
		ActionState.BLINK: _anim.enter_blink()
		# --- 受击/死亡/复活 ---
		ActionState.HURT:
			_anim.enter_hurt(Vector2(params.get("push_x", 0), params.get("push_y", 0)))
		ActionState.STAGGER:
			_anim.settle_to(SpriteAnim.AnimState.STAGGER, facing)
		ActionState.DEAD: _anim.enter_dead()
		ActionState.RESURRECTING:
			_anim.settle_to(SpriteAnim.AnimState.RESURRECTING, facing)
		# --- 交互场景化 ---
		ActionState.DIALOG:   _anim.enter_force_ready("dialog")
		ActionState.FORGE:    _anim.enter_force_ready("forge")
		ActionState.SEARCH, ActionState.PICK_UP, ActionState.OPEN_DOOR:
			_anim.enter_force_ready("search")
		ActionState.DRINK:    _anim.settle_to(SpriteAnim.AnimState.DRINK, facing)
		ActionState.CARRY:    _anim.settle_to(SpriteAnim.AnimState.CARRY, facing)
		ActionState.SIT:      _anim.settle_to(SpriteAnim.AnimState.SIT, facing)
		ActionState.TRAP_SET: _anim.settle_to(SpriteAnim.AnimState.TRAP_SET, facing)
		ActionState.PORTAL:   _anim.settle_to(SpriteAnim.AnimState.PORTAL, facing)
		ActionState.Celebrate: _anim.settle_to(SpriteAnim.AnimState.CELEBRATE, facing)
		ActionState.FALL:     _anim.settle_to(SpriteAnim.AnimState.FALL, facing)
	_frame_set_from_state(target)

func _frame_set_from_state(s: ActionState) -> void:
	if _frame_anim == null:
		return
	var names := _frame_anim.sprite_frames.get_animation_names()
	var map := {
		ActionState.IDLE: "idle", ActionState.WALK: "walk", ActionState.RUN: "walk",
		ActionState.CROUCH: "idle", ActionState.WALK_CROUCH: "walk",
		ActionState.JUMP: "attack", ActionState.JUMP_FALLING: "idle", ActionState.JUMP_LAND: "hit",
		ActionState.SWIM: "walk", ActionState.SWIM_IDLE: "idle",
		ActionState.CLIMB: "walk",
		ActionState.ROLL: "attack",
		ActionState.ATTACK_MELEE: "attack", ActionState.ATTACK_BOW: "attack",
		ActionState.ATTACK_THROW: "attack", ActionState.ATTACK_SPELL: "attack",
		ActionState.ATTACK_SUMMON: "attack", ActionState.ATTACK_CHAIN: "attack",
		ActionState.ATTACK_UNARMED: "attack", ActionState.ATTACK_RAPID: "attack",
		ActionState.ATTACK_AOE: "attack",
		ActionState.CHARGING: "idle", ActionState.CAST_FOCUS: "idle",
		ActionState.BLOCK: "idle", ActionState.READY: "idle",
		ActionState.DASH: "attack", ActionState.BLINK: "attack",
		ActionState.HURT: "hit", ActionState.STAGGER: "hit",
		ActionState.DEAD: "hit", ActionState.RESURRECTING: "idle",
		ActionState.DIALOG: "idle", ActionState.FORGE: "idle",
		ActionState.SEARCH: "idle", ActionState.PICK_UP: "idle",
		ActionState.OPEN_DOOR: "idle", ActionState.DRINK: "idle",
		ActionState.CARRY: "walk", ActionState.SIT: "idle",
		ActionState.TRAP_SET: "idle", ActionState.PORTAL: "attack",
		ActionState.MOUNTED: "walk", ActionState.DISMOUNT: "attack",
		ActionState.Celebrate: "attack", ActionState.FALL: "idle",
	}
	var frame_name: String = map.get(s, "idle")
	if frame_name in names:
		_frame_anim.play(frame_name)

func _state_from_name(n: String) -> ActionState:
	var map := {
		"idle": ActionState.IDLE, "walk": ActionState.WALK, "run": ActionState.RUN,
		"crouch": ActionState.CROUCH, "walk_crouch": ActionState.WALK_CROUCH,
		"prone": ActionState.PRONE, "lurk": ActionState.LURK,
		"jump": ActionState.JUMP, "jump_falling": ActionState.JUMP_FALLING,
		"jump_land": ActionState.JUMP_LAND, "swim": ActionState.SWIM,
		"swim_idle": ActionState.SWIM_IDLE, "climb": ActionState.CLIMB,
		"roll": ActionState.ROLL,
		"mounted": ActionState.MOUNTED, "dismount": ActionState.DISMOUNT,
		"attack_melee": ActionState.ATTACK_MELEE,
		"attack_bow": ActionState.ATTACK_BOW,
		"attack_throw": ActionState.ATTACK_THROW,
		"attack_spell": ActionState.ATTACK_SPELL,
		"attack_summon": ActionState.ATTACK_SUMMON,
		"attack_chain": ActionState.ATTACK_CHAIN,
		"attack_unarmed": ActionState.ATTACK_UNARMED,
		"attack_rapid": ActionState.ATTACK_RAPID,
		"attack_aoe": ActionState.ATTACK_AOE,
		"charging": ActionState.CHARGING, "cast_focus": ActionState.CAST_FOCUS,
		"block": ActionState.BLOCK, "ready": ActionState.READY,
		"dash": ActionState.DASH, "blink": ActionState.BLINK,
		"hurt": ActionState.HURT, "stagger": ActionState.STAGGER,
		"dead": ActionState.DEAD, "resurrecting": ActionState.RESURRECTING,
		"dialog": ActionState.DIALOG, "forge": ActionState.FORGE,
		"search": ActionState.SEARCH, "pick_up": ActionState.PICK_UP,
		"open_door": ActionState.OPEN_DOOR, "drink": ActionState.DRINK,
		"carry": ActionState.CARRY, "sit": ActionState.SIT,
		"trap_set": ActionState.TRAP_SET, "portal": ActionState.PORTAL,
	}
	return map.get(n, ActionState.IDLE)

# -------------------- 灵魂控制：切换形态 --------------------
func soul_bind_to(new_profile_id: String, new_sheet_id: String = "") -> void:
	"""灵魂控制：玩家灵魂附着到新形态。平滑切换 profile + sheet。"""
	var old_sheet := _sheet_id
	var old_profile_id := str(profile.get("id", ""))
	if old_profile_id == new_profile_id:
		return
	# 1. 换 profile（能力集）
	profile = ActionProfileRegistry.get(new_profile_id)
	# 2. 换 sheet（帧动画层）
	if new_sheet_id == "":
		new_sheet_id = str(profile.get("default_sheet", new_profile_id))
	if new_sheet_id != old_sheet:
		_sheet_id = new_sheet_id
		# 销毁旧 frame anim
		if _frame_anim != null and is_instance_valid(_frame_anim):
			_frame_anim.queue_free()
			_frame_anim = null
		_try_attach_frames()
	# 3. 动画过渡：先 flash 一下，再进入 idle
	if _anim:
		_anim.flash(Color(0.8, 0.6, 1.0, 1.0), 0.35)
		_anim.settle_to(SpriteAnim.AnimState.IDLE, facing)
	state = ActionState.IDLE

func update_facing(dir: Vector2) -> void:
	if dir.length() > 0.01:
		facing = dir.normalized()

func flash(c: Color, dur: float = 0.12) -> void:
	if _anim:
		_anim.flash(c, dur)
