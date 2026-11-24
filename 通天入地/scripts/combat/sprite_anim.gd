# ============================================================
# SpriteAnim — 程序化形变动画控制器（13 种独立动作）
#
# 动作类型：
#   基础:    IDLE / RUN / ATTACK / CAST / DASH / HURT / DEAD
#   武器化:  SWORD_SWING / BOW_DRAW / THROW_BOMB
#   职业化:  CAST_SPELL / SUMMON_RITUAL
#   场景化:  FORCE_READY  (对话/搜寻/锻造通用锁定状态)
#
# 每种动作都有专属 Tween 曲线（蓄力→释放→收招），不是简单几帧循环。
# 不依赖 AnimatedSprite2D / SpriteFrames。
# ============================================================

extends Node2D
class_name SpriteAnim

enum AnimState {
	# --- 基础 ---
	IDLE, RUN, ATTACK, CAST, DASH, BLINK, HURT, DEAD, STAGGER, RESURRECTING,
	# --- 武器化 ---
	SWORD_SWING, BOW_DRAW, THROW_BOMB,
	# --- 职业化 ---
	CAST_SPELL, SUMMON_RITUAL,
	# --- 蓄力/专注/防御 ---
	CHARGING, CAST_FOCUS, BLOCK, READY,
	# --- 低姿态 ---
	CROUCH, WALK_CROUCH, PRONE, LURK,
	# --- 移动特殊 ---
	JUMP, JUMP_FALLING, JUMP_LAND, SWIM, CLIMB, ROLL, MOUNTED,
	# --- 场景交互 ---
	FORCE_READY,
	DRINK, CARRY, SIT, TRAP_SET, PORTAL, CELEBRATE, FALL,
	# --- 战斗新 ---
	AOE_SWING, RAPID_STRIKES,
}

var target: Node2D = null
var _is_character_body := false
var state: AnimState = AnimState.IDLE
var facing: Vector2 = Vector2.DOWN
var move_mag: float = 0.0
var _breath_t: float = 0.0
var _base_offset: Vector2 = Vector2.ZERO
var _base_scale: Vector2 = Vector2.ONE
var _active_offset: Vector2 = Vector2.ZERO
var _active_rotation: float = 0.0
var _active_scale_mult: float = 1.0
var _ghost_timer: float = 0.0
var _attack_timer: float = 0.0
var _attack_total: float = 0.0
var _attack_target_pos: Vector2 = Vector2.ZERO
var _attack_range: float = 0.0
var _attack_kind: String = ""  # "melee" | "projectile" | "bow" | "swing" | "bomb" | "spell" | "summon"
var _hurt_timer: float = 0.0
var _hurt_push: Vector2 = Vector2.ZERO
var _dead_timer: float = 0.0
var _color_tween: Tween = null
var _mod_flash: float = 0.0
var _flash_color: Color = Color.WHITE
var _ghost_spawn_interval: float = 0.055
var _ghost_last_spawn: float = 0.0
var _ghost_lifetime: float = 0.18
# FORCE_READY 子状态（场景化状态内部细分）
var _force_subtype: String = "dialog"  # "dialog" | "search" | "forge"
var _force_timer: float = 0.0
# 新增状态参数
var _roll_dir: float = 1.0
var _rapid_count: int = 3
var _rapid_each: float = 0.18
var _aoe_radius: float = 60.0

func setup(owner: Node2D) -> void:
	target = owner
	_is_character_body = owner is CharacterBody2D
	if _is_character_body:
		_base_offset = Vector2.ZERO
	else:
		_base_offset = owner.position
	if owner is Sprite2D:
		_base_scale = owner.scale
	else:
		_base_scale = Vector2.ONE

func _process(delta: float) -> void:
	if target == null:
		return
	_breath_t += delta

	# 伤害闪烁
	var color := Color(1.0, 1.0, 1.0, 1.0)
	if _mod_flash > 0.0:
		_mod_flash -= delta
		var t := clampf(_mod_flash / 0.12, 0.0, 1.0)
		color = Color(_flash_color.r, _flash_color.g, _flash_color.b, 1.0)
		color.r = lerpf(color.r, 1.0, 1.0 - t)
		color.g = lerpf(color.g, 1.0, 1.0 - t)
		color.b = lerpf(color.b, 1.0, 1.0 - t)
	if target.has_method("set_modulate"):
		target.modulate = color

	# 呼吸
	var breath_speed := 2.6 if state == AnimState.RUN else 1.6
	var breath_strength := 2.2 if state == AnimState.RUN else 1.2
	var breath_y := sin(_breath_t * breath_speed) * breath_strength
	var breath_x := cos(_breath_t * breath_speed * 0.5) * breath_strength * 0.3

	var action_offset := Vector2(breath_x, breath_y)
	var action_scale := Vector2.ONE
	var action_rot := 0.0

	match state:
		AnimState.IDLE:
			# 细腻呼吸 + 微重心摇摆 + 眨眼（模拟）
			var s_idle := 1.0 + sin(_breath_t * 1.4) * 0.02
			action_scale = Vector2(s_idle, s_idle)
			action_offset.x += sin(_breath_t * 0.9) * 0.8
			action_offset.y += sin(_breath_t * 2.2) * 0.4
			action_rot = sin(_breath_t * 0.6) * 0.015
		AnimState.RUN:
			var run_step := sin(_breath_t * 9.0)
			action_offset.y += run_step * 3.0
			action_offset.x += run_step * facing.x * 2.0
			var s_run := 1.0 + run_step * 0.04
			action_scale = Vector2(s_run, s_run)
			action_rot = run_step * facing.x * 0.04
		AnimState.ATTACK:
			var t := clampf(_attack_timer / maxf(_attack_total, 0.001), 0.0, 1.0)
			if _attack_kind == "melee":
				# 三段式：蓄力(t<0.22) → 前冲命中(0.22~0.55) → 收招(0.55~1.0)
				var forward = facing * _attack_range
				var kf_mult: float = 0.0; var scale_k: float = 1.0; var rot_k: float = 0.0
				if t < 0.22:
					kf_mult = -sin(t / 0.22 * PI) * 0.35
					scale_k = 1.12 - sin(t / 0.22 * PI) * 0.07
					rot_k = -facing.x * 0.18 * (t / 0.22)
				elif t < 0.55:
					var t2 := (t - 0.22) / 0.33
					kf_mult = sin(t2 * PI) * 1.1
					scale_k = 1.08 + sin(t2 * PI) * 0.06
					rot_k = facing.x * 0.28 * sin(t2 * PI)
				else:
					var t3 := (t - 0.55) / 0.45
					kf_mult = 0.35 * sin(PI + t3 * PI * 0.6)
					scale_k = 1.0 + 0.02 * sin(t3 * PI * 2.0)
					rot_k = facing.x * 0.1 * sin(t3 * PI * 0.8)
				action_offset = forward * kf_mult * 0.7 + Vector2(0, sin(_breath_t * 8) * 1.2)
				action_scale = Vector2(scale_k, scale_k); action_rot = rot_k
			else:
				var offset_vec := Vector2.ZERO; var rot_k2: float = 0.0; var scale_k2: float = 1.0
				if t < 0.35:
					var t2 := t / 0.35
					offset_vec = -facing * 4.0 * sin(t2 * PI)
					rot_k2 = -facing.x * 0.14 * sin(t2 * PI)
					scale_k2 = 0.93 + 0.07 * t2
				elif t < 0.55:
					var t2 := (t - 0.35) / 0.2
					offset_vec = facing * 3.0 * sin(t2 * PI)
					rot_k2 = facing.x * 0.22 * sin(t2 * PI)
					scale_k2 = 1.04
				else:
					var t3 := (t - 0.55) / 0.45
					offset_vec = -facing * 1.0 * sin(t3 * PI * 0.8)
					rot_k2 = facing.x * 0.06 * sin(t3 * PI)
					scale_k2 = 1.0
				action_offset = offset_vec + Vector2(0, sin(_breath_t * 6) * 0.6)
				action_rot = rot_k2; action_scale = Vector2(scale_k2, scale_k2)
		# ============ 新动作 1：SWORD_SWING 剑/斧挥砍 ============
		AnimState.SWORD_SWING:
			var t := clampf(_attack_timer / maxf(_attack_total, 0.001), 0.0, 1.0)
			var forward = facing * _attack_range
			var kf_mult: float = 0.0; var scale_k: float = 1.0; var rot_k: float = 0.0
			if t < 0.18:
				# 蓄力：身体后压 + 剑往后摆
				kf_mult = -sin(t / 0.18 * PI) * 0.3
				scale_k = 1.08 - sin(t / 0.18 * PI) * 0.05
				rot_k = -0.45 * (t / 0.18) * facing.x
			elif t < 0.42:
				# 挥击：大幅前冲 + 旋转 -0.45 → +0.45 弧度（过顶劈）
				var t2 := (t - 0.18) / 0.24
				kf_mult = sin(t2 * PI) * 1.4
				scale_k = 1.12 + sin(t2 * PI) * 0.08
				rot_k = lerpf(-0.45, 0.45, t2) * facing.x
			elif t < 0.62:
				# 劈完回摆
				var t3 := (t - 0.42) / 0.2
				kf_mult = 0.7 * sin(PI - t3 * PI)
				scale_k = 1.05
				rot_k = 0.45 * (1.0 - t3) * facing.x
			else:
				var t4 := (t - 0.62) / 0.38
				kf_mult = -0.2 * sin(t4 * PI * 0.5)
				rot_k = 0.08 * sin(t4 * PI) * facing.x
			action_offset = forward * kf_mult * 0.7
			action_scale = Vector2(scale_k, scale_k); action_rot = rot_k
		# ============ 新动作 2：BOW_DRAW 弓拉弦 ============
		AnimState.BOW_DRAW:
			var t := clampf(_attack_timer / maxf(_attack_total, 0.001), 0.0, 1.0)
			var back = -facing  # 拉弓往回
			var kf_mult: float = 0.0; var scale_k: float = 1.0; var rot_k: float = 0.0
			if t < 0.55:
				# 蓄力：缓慢后拉 + body 压缩
				var t2 := t / 0.55
				kf_mult = sin(t2 * PI) * 1.0
				scale_k = 0.94 + t2 * 0.06
				rot_k = -facing.x * 0.08 * t2
				action_offset = back * kf_mult + Vector2(0, -2.0 * sin(t2 * PI))
			elif t < 0.72:
				# 放箭！前冲 + 反弹
				var t2 := (t - 0.55) / 0.17
				kf_mult = sin(t2 * PI) * 1.3
				scale_k = 1.10
				rot_k = facing.x * 0.15
				action_offset = facing * kf_mult + Vector2(0, -3.0 * sin(t2 * PI))
			else:
				var t3 := (t - 0.72) / 0.28
				kf_mult = 0.3 * sin(t3 * PI * 0.6)
				scale_k = 1.0
				action_offset = facing * kf_mult
			action_scale = Vector2(scale_k, scale_k); action_rot = rot_k
		# ============ 新动作 3：THROW_BOMB 投掷炸弹 ============
		AnimState.THROW_BOMB:
			var t := clampf(_attack_timer / maxf(_attack_total, 0.001), 0.0, 1.0)
			var kf_mult: float = 0.0; var scale_k: float = 1.0; var rot_k: float = 0.0
			if t < 0.4:
				# 蓄力：下蹲 + 身体后仰（手往后拉）
				var t2 := t / 0.4
				kf_mult = -sin(t2 * PI) * 0.3
				scale_k = 0.92 + sin(t2 * PI) * 0.03
				rot_k = -facing.x * 0.25 * (t2)
				action_offset = facing * kf_mult + Vector2(0, sin(t2 * PI) * 2.0)
			elif t < 0.55:
				# 上抛！身体弹起 + 前倾（手往前上抛）
				var t2 := (t - 0.4) / 0.15
				kf_mult = sin(t2 * PI) * 0.5
				scale_k = 1.08
				rot_k = facing.x * 0.35 * sin(t2 * PI)
				action_offset = facing * kf_mult + Vector2(0, -5.0 * sin(t2 * PI))
			else:
				var t3 := (t - 0.55) / 0.45
				scale_k = 1.0 - 0.05 * (1.0 - t3)
				rot_k = facing.x * 0.12 * sin(t3 * PI * 0.5)
				action_offset = Vector2(0, 0.5 * sin(t3 * PI))
			action_scale = Vector2(scale_k, scale_k); action_rot = rot_k
		# ============ 新动作 4：CAST_SPELL 法术咏唱 ============
		AnimState.CAST_SPELL:
			var t := clampf(_attack_timer / maxf(_attack_total, 0.001), 0.0, 1.0)
			# 法师：双手上抬 -6px + 身体快速脉动 scale + 轻微左右摇摆
			action_offset = Vector2(sin(t * PI * 4) * 1.5, -3.0 * sin(t * PI * 2.5))
			var s_cs := 1.0 + 0.08 * sin(t * PI * 5)
			action_scale = Vector2(s_cs, s_cs)
			action_rot = sin(t * PI * 3) * 0.04
		# ============ 新动作 5：SUMMON_RITUAL 召唤法阵 ============
		AnimState.SUMMON_RITUAL:
			var t := clampf(_attack_timer / maxf(_attack_total, 0.001), 0.0, 1.0)
			action_offset = Vector2(sin(t * PI * 2) * 2.0, 2.0 * sin(t * PI * 3))
			var s_sr := 1.0 + 0.12 * sin(t * PI * 2)
			action_scale = Vector2(s_sr, s_sr)
			action_rot = sin(t * PI * 1.5) * 0.08
		# ============ 低姿态新增（独立于 FORCE_READY）============
		AnimState.CROUCH:
			# 蹲下：身体压扁 + 重心下移 + 轻微呼吸
			action_scale = Vector2(1.05, 0.78)
			action_offset = Vector2(0, 6.0 + sin(_breath_t * 2) * 0.5)
			action_rot = 0.0
		AnimState.WALK_CROUCH:
			# 蹲走：压扁 + 下移 + 小步频摆动
			var step := sin(_breath_t * 6.5)
			action_scale = Vector2(1.05, 0.78)
			action_offset = Vector2(step * 1.5, 6.0 + step * 1.2)
			action_rot = step * facing.x * 0.02
		AnimState.PRONE:
			# 趴下：完全压扁 + 平躺 + 轻微呼吸
			action_scale = Vector2(1.15, 0.45)
			action_offset = Vector2(0, 12.0)
			action_rot = sin(_breath_t * 1.2) * 0.03
		AnimState.LURK:
			# 潜伏：半蹲 + 左右探头 + 身体微微发抖
			var peek := sin(_breath_t * 1.8)
			action_scale = Vector2(1.02, 0.88)
			action_offset = Vector2(peek * 2.5, 3.5)
			action_rot = peek * 0.05 + sin(_breath_t * 11) * 0.008  # 微抖
			# 透明度脉动（隐形感）
			color.a = 0.85 + sin(_breath_t * 2.5) * 0.1
			target.modulate = color
		# ============ 新增动作：蓄力/专注/防御 ============
		AnimState.CHARGING:
			# 蓄力：身体慢慢压缩 + 能量汇聚（脉动 scale）
			action_scale = Vector2(0.92, 1.08) + Vector2(0, 0.04) * sin(_breath_t * 5.0)
			action_offset = Vector2(0, 1.5 + 1.0 * sin(_breath_t * 6.0))
			action_rot = 0.0
			# 外发光脉动
			color = Color(1.0, 0.9, 0.6, 1.0) + Color(0.1, 0.1, 0.0, 0) * sin(_breath_t * 8.0)
			target.modulate = color
		AnimState.CAST_FOCUS:
			# 长施法：双手高举 + 光环慢慢生成（放大 + 脉动）
			var s_cf := 1.0 + 0.1 * sin(_breath_t * 2.0)
			action_scale = Vector2(s_cf, s_cf)
			action_offset = Vector2(0, -2.0)
			action_rot = sin(_breath_t * 1.5) * 0.03
			color = Color(0.85, 0.9, 1.0, 1.0) + Color(0.08, 0.08, 0.12, 0) * sin(_breath_t * 3.0)
			target.modulate = color
		AnimState.BLOCK:
			# 举盾格挡：身体微侧 + 盾在前（用 facing 方向偏移）
			action_scale = Vector2(1.02, 0.98)
			action_offset = Vector2(-facing.x * 2.0, 0)
			action_rot = -facing.x * 0.04  # 身体向盾侧微旋
		AnimState.READY:
			# 武器举起重试：不动但有呼吸 + 身体微微前后摇摆
			var s_rd := 1.0 + 0.02 * sin(_breath_t * 2.0)
			action_scale = Vector2(s_rd, s_rd)
			action_offset = Vector2(facing.x * sin(_breath_t * 1.5) * 1.5, 0)
			action_rot = 0.0
		# ============ 新增：跳跃三件套 ============
		AnimState.JUMP:
			# 起跳：身体快速伸展 + 轻微旋转
			var tj := clampf(1.0 - _attack_timer / maxf(_attack_total, 0.001), 0.0, 1.0)
			action_scale = Vector2(0.9, 1.15) * (1.0 - tj) + Vector2(1.05, 0.95) * tj
			action_offset = Vector2(0, -8.0 * tj)
			action_rot = facing.x * 0.1 * tj
		AnimState.JUMP_FALLING:
			# 下落：身体收缩 + 下坠加速感
			action_scale = Vector2(1.1, 0.88)
			action_offset = Vector2(0, 0)
			action_rot = facing.x * -0.05
		AnimState.JUMP_LAND:
			# 落地：压缩 + 回弹
			var tl := sin(_force_timer / 0.15 * PI)
			action_scale = Vector2(1.12 - 0.12 * tl, 0.85 + 0.15 * tl)
			action_offset = Vector2(0, 6.0 - 4.0 * tl)
			action_rot = facing.x * 0.05 * (1.0 - tl)
		# ============ 新增：游泳/攀爬/翻滚/骑乘 ============
		AnimState.SWIM:
			# 游泳：身体上下浮动 + 手臂划水（小旋转）
			action_scale = Vector2(1.05, 0.95)
			action_offset = Vector2(0, sin(_breath_t * 5.0) * 3.0)
			action_rot = sin(_breath_t * 5.0) * 0.05
		AnimState.CLIMB:
			# 攀爬：身体微收 + 左右摆动
			action_scale = Vector2(0.9, 1.05)
			action_offset = Vector2(sin(_breath_t * 4.0) * 1.0, 0)
			action_rot = sin(_breath_t * 4.0) * 0.04
		AnimState.ROLL:
			# 翻滚：360° 旋转 + 压扁 + 快速位移
			var tr := clampf(_force_timer / 0.35, 0.0, 1.0)
			action_scale = Vector2(0.5, 1.3) + Vector2(0.4, -0.3) * sin(tr * PI)
			action_offset = Vector2(_roll_dir * 20.0 * tr, -4.0 * sin(tr * PI))
			action_rot = _roll_dir * tr * PI * 2.0  # 360° 旋转
			color.a = 0.7 + 0.3 * sin(tr * PI)  # 半透明残影感
			target.modulate = color
		AnimState.MOUNTED:
			# 骑乘：稳定坐姿 + 随坐骑颠簸
			action_scale = Vector2(0.95, 0.92)
			action_offset = Vector2(0, -2.0 + sin(_breath_t * 8.0) * 1.0)
			action_rot = sin(_breath_t * 4.0) * 0.02
		# ============ 新增：战斗新动作 ============
		AnimState.AOE_SWING:
			# 范围重斩：大旋转 + 前冲
			var ta := clampf(_attack_timer / maxf(_attack_total, 0.001), 0.0, 1.0)
			var strike := 1.0 if ta >= 0.5 else 0.0
			action_offset = Vector2(facing.x * 40.0 * sin(ta * PI), facing.y * 40.0 * sin(ta * PI)) * strike
			var s_aoe := 1.0 + 0.15 * sin(ta * PI)
			action_scale = Vector2(s_aoe, s_aoe)
			action_rot = sin(ta * PI) * 1.2
		AnimState.RAPID_STRIKES:
			# 快速连击：每段独立挥舞
			var ts := _attack_timer / maxf(_attack_total, 0.001) * float(_rapid_count)
			var ts_local := fmod(ts, 1.0)
			var odd_flicker := 1.0 if int(ts) % 2 == 0 else -1.0
			action_offset = Vector2(facing.x * 30.0 * sin(ts_local * PI) * odd_flicker, facing.y * 30.0 * sin(ts_local * PI))
			var s_rapid := 1.0 + 0.1 * sin(ts_local * PI)
			action_scale = Vector2(s_rapid, s_rapid)
			action_rot = odd_flicker * sin(ts_local * PI) * 0.8
		# ============ 新增：场景交互 ============
		AnimState.DRINK:
			# 喝药水：头微抬 + 身体前倾 + 小幅度上下
			var td := sin(_breath_t * 3.0)
			action_scale = Vector2(1.0, 1.02)
			action_offset = Vector2(0, -1.5 + td * 1.0)
			action_rot = facing.x * 0.02
		AnimState.CARRY:
			# 搬东西：身体后倾（负重）+ 重心下移 + 脚步小摆
			var tc := sin(_breath_t * 5.0)
			action_scale = Vector2(1.05, 1.0)
			action_offset = Vector2(-facing.x * 1.5, 2.0 + tc * 1.0)
			action_rot = -facing.x * 0.03
		AnimState.SIT:
			# 坐下：压扁 + 下移 + 静止呼吸
			action_scale = Vector2(1.02, 0.82)
			action_offset = Vector2(0, 5.0 + sin(_breath_t * 1.2) * 0.5)
			action_rot = 0.0
		AnimState.TRAP_SET:
			# 放陷阱：身体前倾 + 手向下伸
			action_scale = Vector2(1.0, 0.95)
			action_offset = Vector2(0, 3.0)
			action_rot = facing.x * 0.05
		AnimState.PORTAL:
			# 传送仪式：身体慢慢浮起 + 旋转 + 脉动光环
			var tp := sin(_breath_t * 2.0)
			var s_portal := 1.0 + 0.1 * tp
			action_scale = Vector2(s_portal, s_portal)
			action_offset = Vector2(0, -3.0 - tp * 3.0)
			action_rot = tp * 0.3
		AnimState.CELEBRATE:
			# 庆祝：跳跃 + 举武器 + 左右摇摆
			action_scale = Vector2(1.0, 1.0 + 0.08 * sin(_breath_t * 3.0))
			action_offset = Vector2(sin(_breath_t * 2.0) * 3.0, -4.0 * abs(sin(_breath_t * 3.0)))
			action_rot = sin(_breath_t * 4.0) * 0.08
		AnimState.FALL:
			# 跌落：身体垂直 + 快速旋转 + 缩放变化
			action_scale = Vector2(1.0 - 0.1 * sin(_breath_t * 8.0), 1.0 + 0.15 * sin(_breath_t * 8.0))
			action_offset = Vector2(0, 0)
			action_rot = _breath_t * 6.0  # 快速旋转
		AnimState.STAGGER:
			# 硬直：身体后仰 + 小幅抖动 + 透明度降低
			action_scale = Vector2(0.95, 1.05)
			action_offset = Vector2(facing.x * 3.0 + sin(_breath_t * 20.0) * 0.5, 1.0)
			action_rot = -facing.x * 0.08
		AnimState.RESURRECTING:
			# 复活：身体慢慢弹起 + 缩放恢复 + 颜色变白
			var tr := sin(_breath_t * 1.0)
			action_scale = Vector2(0.9 + 0.1 * tr, 0.85 + 0.15 * tr)
			action_offset = Vector2(0, -4.0 * tr)
			action_rot = 0.0
			color = Color(1.0, 1.0, 1.0, 0.9) + Color(0, 0.2, 0.3, 0) * tr
			target.modulate = color
		# ============ CAST 旧分支 ============
		AnimState.CAST:
			var t_cast := clampf(_attack_timer / maxf(_attack_total, 0.001), 0.0, 1.0)
			action_offset = Vector2(0, -2.0 * sin(t_cast * PI * 3))
			var s_cast := 1.0 + 0.06 * sin(t_cast * PI * 4)
			action_scale = Vector2(s_cast, s_cast)
		AnimState.DASH:
			var s_dash := 1.0 + sin(_breath_t * 20) * 0.04
			action_scale = Vector2(s_dash, s_dash)
		AnimState.HURT:
			var t := clampf(_hurt_timer / maxf(0.22, 0.001), 0.0, 1.0)
			action_offset = _hurt_push * (1.0 - t) + Vector2(0, sin(_breath_t * 12) * 2.0 * (1.0 - t))
			action_rot = _hurt_push.x * 0.15 * (1.0 - t)
		AnimState.DEAD:
			var t := clampf(_dead_timer / maxf(0.8, 0.001), 0.0, 1.0)
			action_rot = PI * 0.25 * t
			var s_dead := 1.0 - 0.2 * t
			action_scale = Vector2(s_dead, s_dead)
			color.a = 1.0 - 0.5 * t
			target.modulate = color
		# ============ 新动作 6：FORCE_READY 对话/搜寻/锻造 ============
		AnimState.FORCE_READY:
			_force_timer += delta
			match _force_subtype:
				"dialog":
					# 对话：轻微前后摇摆 + 每 1.2s 眨一次眼（缩一下）
					action_offset.x = sin(_breath_t * 1.0) * 1.5
					action_offset.y = -1.0 + sin(_breath_t * 1.8) * 0.8
					var s_dialog := 0.99 + sin(_breath_t * 1.0) * 0.01
					action_scale = Vector2(s_dialog, s_dialog)
					action_rot = sin(_breath_t * 0.7) * 0.025
					# 眨眼（身体快速缩一下模拟）
					if fmod(_force_timer, 2.4) < 0.08:
						action_scale *= 0.94
				"search":
					# 搜寻：身体前倾 + 左右快速张望
					action_offset.y = -2.5  # 前倾
					action_offset.x = sin(_breath_t * 3.2) * 4.0  # 左右快速扫
					action_rot = sin(_breath_t * 3.2) * 0.08 * facing.x
					action_scale = Vector2.ONE
				"forge":
					# 锻造：规律性上下锤 + 身体缩放
					var hammer_t := fmod(_force_timer, 0.75) / 0.75
					# 锤子循环：蓄力(0~0.35) → 敲击(0.35~0.4) → 抬起(0.4~0.75)
					if hammer_t < 0.35:
						var t2 := hammer_t / 0.35
						action_offset.y = -4.0 * sin(t2 * PI)  # 抬手蓄力
						action_scale = Vector2(1.02, 1.02)
					elif hammer_t < 0.45:
						var t2 := (hammer_t - 0.35) / 0.1
						action_offset.y = -4.0 + 10.0 * t2  # 快速砸下
						var s_forge := 0.94 - t2 * 0.04
						action_scale = Vector2(s_forge, s_forge)
						action_rot = facing.x * 0.15 * (1.0 - t2)  # 锤砸时身体旋转
					else:
						var t2 := (hammer_t - 0.45) / 0.3
						action_offset.y = 6.0 * (1.0 - t2)  # 慢慢抬起
						action_scale = Vector2.ONE
						action_rot *= (1.0 - t2)

	# 冲刺残影
	if state == AnimState.DASH:
		_ghost_last_spawn += delta
		if _ghost_last_spawn >= _ghost_spawn_interval:
			_ghost_last_spawn = 0.0
			_spawn_ghost()

	# 应用组合
	var final_offset := _base_offset + action_offset + _active_offset
	if _is_character_body:
		target.set("visual_offset", final_offset)
	else:
		target.position = final_offset
	target.rotation = _active_rotation + action_rot
	target.scale = _base_scale * _active_scale_mult * action_scale

	if _attack_timer > 0.0:
		_attack_timer -= delta
	if _hurt_timer > 0.0:
		_hurt_timer -= delta
	if _dead_timer > 0.0:
		_dead_timer -= delta


# ---------- 公共 API ----------

func enter_attack(fkind: String, range: float, duration: float, target_pos: Vector2 = Vector2.ZERO, dir: Vector2 = Vector2.ZERO) -> void:
	state = AnimState.ATTACK
	_attack_kind = fkind
	_attack_range = range
	_attack_total = duration
	_attack_timer = duration
	if dir.length() > 0.01:
		facing = dir.normalized()
	if target_pos.length() > 0.001:
		_attack_target_pos = target_pos


func enter_sword_swing(range: float, duration: float = 0.35, dir: Vector2 = Vector2.ZERO) -> void:
	state = AnimState.SWORD_SWING
	_attack_kind = "swing"
	_attack_range = range
	_attack_total = duration
	_attack_timer = duration
	if dir.length() > 0.01:
		facing = dir.normalized()


func enter_bow_draw(duration: float = 0.42, dir: Vector2 = Vector2.ZERO) -> void:
	state = AnimState.BOW_DRAW
	_attack_kind = "bow"
	_attack_total = duration
	_attack_timer = duration
	if dir.length() > 0.01:
		facing = dir.normalized()


func enter_throw_bomb(duration: float = 0.45, dir: Vector2 = Vector2.ZERO) -> void:
	state = AnimState.THROW_BOMB
	_attack_kind = "bomb"
	_attack_total = duration
	_attack_timer = duration
	if dir.length() > 0.01:
		facing = dir.normalized()


func enter_cast_spell(duration: float = 0.45, dir: Vector2 = Vector2.ZERO) -> void:
	state = AnimState.CAST_SPELL
	_attack_kind = "spell"
	_attack_total = duration
	_attack_timer = duration
	if dir.length() > 0.01:
		facing = dir.normalized()


func enter_summon_ritual(duration: float = 0.65, dir: Vector2 = Vector2.ZERO) -> void:
	state = AnimState.SUMMON_RITUAL
	_attack_kind = "summon"
	_attack_total = duration
	_attack_timer = duration
	if dir.length() > 0.01:
		facing = dir.normalized()


func enter_cast(duration: float, dir: Vector2 = Vector2.ZERO) -> void:
	state = AnimState.CAST
	_attack_kind = "cast"
	_attack_total = duration
	_attack_timer = duration
	if dir.length() > 0.01:
		facing = dir.normalized()


func enter_dash() -> void:
	state = AnimState.DASH
	_ghost_last_spawn = _ghost_spawn_interval
	_spawn_ghost()
	_spawn_ghost()


func enter_hurt(push_dir: Vector2, flash_color: Color = Color(1.0, 0.5, 0.5)) -> void:
	state = AnimState.HURT
	_hurt_push = push_dir * 8.0
	_hurt_timer = 0.22
	flash(flash_color, 0.12)


func enter_dead() -> void:
	state = AnimState.DEAD
	_dead_timer = 0.0


func enter_force_ready(subtype: String = "dialog") -> void:
	state = AnimState.FORCE_READY
	_force_subtype = subtype
	_force_timer = 0.0


# --- 新增 setter ---
func enter_jump(jump_phase: int) -> void:
	# jump_phase: ActionState.JUMP/JUMP_FALLING/JUMP_LAND 的值
	if jump_phase == 6:       # JUMP
		state = AnimState.JUMP
	elif jump_phase == 7:    # JUMP_FALLING
		state = AnimState.JUMP_FALLING
	else:
		state = AnimState.JUMP_LAND


func enter_roll(dir_x: float) -> void:
	state = AnimState.ROLL
	_roll_dir = sign(dir_x) if dir_x != 0 else facing.x
	_force_timer = 0.0
	_attack_total = 0.35


func enter_blink() -> void:
	state = AnimState.BLINK
	_force_timer = 0.0
	_attack_total = 0.15


func enter_rapid_strikes(count: int, duration_each: float, dir: Vector2) -> void:
	state = AnimState.RAPID_STRIKES
	facing = dir
	_attack_timer = 0.0
	_attack_total = duration_each * float(count)
	_rapid_count = count
	_rapid_each = duration_each


func enter_aoe_swing(radius: float, duration: float, dir: Vector2) -> void:
	state = AnimState.AOE_SWING
	facing = dir
	_attack_timer = 0.0
	_attack_total = duration
	_aoe_radius = radius


func settle_to(next_state: AnimState, new_facing: Vector2, move_m: float = 0.0) -> void:
	if state == AnimState.HURT or state == AnimState.FORCE_READY:
		return
	state = next_state
	if new_facing.length() > 0.01:
		facing = new_facing.normalized()
	move_mag = move_m


func flash(color_value: Color = Color.WHITE, dur: float = 0.12) -> void:
	_flash_color = color_value
	_mod_flash = dur


func _spawn_ghost() -> void:
	if target == null or target.get_parent() == null or not (target is Node2D):
		return
	var ghost := Sprite2D.new()
	var src: Texture2D = null
	if target is Sprite2D:
		src = (target as Sprite2D).texture
	else:
		var vis = target.get_node_or_null("Visual")
		if vis:
			for c in vis.get_children():
				if c is Sprite2D and (c as Sprite2D).texture:
					src = (c as Sprite2D).texture
					break
	if src == null:
		return
	ghost.texture = src
	ghost.global_position = (target as Node2D).global_position
	ghost.rotation = (target as Node2D).rotation
	ghost.scale = target.scale * 0.9
	ghost.z_index = (target.z_index + 1)
	ghost.modulate = Color(0.85, 0.95, 1.0, 0.7)
	ghost.material = CanvasItemMaterial.new()
	ghost.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	target.get_parent().add_child(ghost)
	var tween := ghost.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "modulate:a", 0.0, _ghost_lifetime)
	tween.tween_property(ghost, "scale", ghost.scale * 0.6, _ghost_lifetime)
	tween.chain().tween_callback(ghost.queue_free)
