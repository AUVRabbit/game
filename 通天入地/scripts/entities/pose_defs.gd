# ============================================================
# PoseDefs — 所有角色姿势的关节时间曲线（数据驱动）
#
# 关节索引（固定）:
#   0 = Pelvis (根)
#   1 = Torso  (躯干, offset 0,-16)
#   2 = Head   (头, offset 0,-14)
#   3 = ArmL   (左臂, offset -10,-4)
#   4 = ArmR   (右臂, offset +10,-4)
#   5 = LegL   (左腿, offset -5,0)
#   6 = LegR   (右腿, offset +5,0)
#
# 循环姿势 (loop): 用 sin(time * freq) 驱动关节摆动
#   rotation 单位: 度
#   offset 单位: px（相对父关节的局部偏移）
#
# 一次性姿势 (timeline): 从 t=0 到 t=duration 插值
#   每帧直接读当前时间点的关节值
#
# 所有姿势的 rotation_y 用 facing 翻转（±1）
# ============================================================

class_name PoseDefs

# —— 循环姿势的结构:
#   {
#     "frequency": float,          # 每秒循环次数
#     "amplitude": float,          # 基础摆动幅度（度/px）
#     "rotations": [int, ...],     # 每个关节的基础 rotation（度）
#     "swing": [float, ...],       # 每个关节的摆动系数（-1..1）, 0=不摆
#     "offsets": [[x,y], ...],     # 每个关节的基础局部偏移（相对父关节）
#     "bob": float                 # 整体上下浮动（pelvis 垂直位移，px）
#   }

static func LOOP_POSES() -> Dictionary:
	return {
		# —— Idle 呼吸 ——
		"idle": {
			"frequency": 1.2,
			"amplitude": 1.0,
			"rotations": [0.0, -0.5, 1.0, -3.0, 3.0, 0.0, 0.0],
			"swing":     [0.0, 0.2, 0.3, 0.2, -0.2, 0.0, 0.0],
			"offsets": [
				Vector2(0, 0),
				Vector2(0, -16),
				Vector2(0, -14),
				Vector2(-10, -4),
				Vector2(10, -4),
				Vector2(-5, 0),
				Vector2(5, 0),
			],
			"bob": 0.8,
		},

		# —— Run 摆臂摆腿 ——
		"run": {
			"frequency": 3.2,
			"amplitude": 1.0,
			"rotations": [0.0, 2.0, 0.0, 0.0, 0.0, 0.0, 0.0],
			"swing":     [0.0, 0.3, 0.0, 0.9, -0.9, 1.0, -1.0],
			"offsets": [
				Vector2(0, 0),
				Vector2(0, -16),
				Vector2(0, -14),
				Vector2(-10, -4),
				Vector2(10, -4),
				Vector2(-5, 0),
				Vector2(5, 0),
			],
			"bob": 2.5,
		},

		# —— Walk 慢速 ——
		"walk": {
			"frequency": 1.8,
			"amplitude": 1.0,
			"rotations": [0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0],
			"swing":     [0.0, 0.15, 0.0, 0.4, -0.4, 0.5, -0.5],
			"offsets": [
				Vector2(0, 0),
				Vector2(0, -16),
				Vector2(0, -14),
				Vector2(-10, -4),
				Vector2(10, -4),
				Vector2(-5, 0),
				Vector2(5, 0),
			],
			"bob": 1.2,
		},

		# —— Hurt 抖动 ——
		"hurt_shake": {
			"frequency": 18.0,
			"amplitude": 1.0,
			"rotations": [0.0, -4.0, 0.0, 0.0, 0.0, 0.0, 0.0],
			"swing":     [0.5, 0.8, 0.6, 0.3, 0.3, 0.0, 0.0],
			"offsets": [
				Vector2(0, 0),
				Vector2(0, -16),
				Vector2(0, -14),
				Vector2(-10, -4),
				Vector2(10, -4),
				Vector2(-5, 0),
				Vector2(5, 0),
			],
			"bob": 0.0,
		},

		# —— Cast 咏唱 (双手抬起) ——
		"cast_loop": {
			"frequency": 0.9,
			"amplitude": 1.0,
			"rotations": [0.0, 1.0, 2.0, 120.0, -120.0, 0.0, 0.0],
			"swing":     [0.0, 0.15, 0.2, 0.3, -0.3, 0.0, 0.0],
			"offsets": [
				Vector2(0, 0),
				Vector2(0, -16),
				Vector2(0, -14),
				Vector2(-6, -20),
				Vector2(6, -20),
				Vector2(-5, 0),
				Vector2(5, 0),
			],
			"bob": 0.6,
		},

		# —— Celebrate 庆祝 ——
		"celebrate": {
			"frequency": 2.4,
			"amplitude": 1.0,
			"rotations": [0.0, -1.0, 0.0, 140.0, -140.0, 0.0, 0.0],
			"swing":     [0.0, 0.2, 0.0, -0.6, 0.6, 0.0, 0.0],
			"offsets": [
				Vector2(0, 0),
				Vector2(0, -16),
				Vector2(0, -14),
				Vector2(-8, -24),
				Vector2(8, -24),
				Vector2(-5, 0),
				Vector2(5, 0),
			],
			"bob": 5.0,
		},
	}


# —— 一次性姿势 (timeline):
#   从 t=0 到 t=duration 线性插值 rotation + offsets
#   用 keyframes 对: [time, [rotations], [offsets], bob, scale_y]

static func TIMELINE_POSES() -> Dictionary:
	return {
		# —— Sword Swing 剑挥 (0.35s) ——
		"sword_swing": {
			"duration": 0.35,
			"keyframes": [
				[0.0,
				 [0.0, 0.0, 0.0, -30.0, 140.0, 0.0, 0.0],
				 [
				 	Vector2(0, 0),
				 	Vector2(0, -16),
				 	Vector2(0, -14),
				 	Vector2(-10, -4),
				 	Vector2(14, -2),
				 	Vector2(-5, 0),
				 	Vector2(5, 0),
				 ],
				 0.0, 1.0],
				[0.5,
				 [0.0, 6.0, 2.0, -60.0, 200.0, -6.0, 6.0],
				 [
				 	Vector2(2, -2),
				 	Vector2(2, -16),
				 	Vector2(2, -14),
				 	Vector2(-14, -6),
				 	Vector2(26, -6),
				 	Vector2(-8, 2),
				 	Vector2(8, 2),
				 ],
				 -3.0, 1.02],
				[1.0,
				 [0.0, 0.0, 0.0, -3.0, 3.0, 0.0, 0.0],
				 [
				 	Vector2(0, 0),
				 	Vector2(0, -16),
				 	Vector2(0, -14),
				 	Vector2(-10, -4),
				 	Vector2(10, -4),
				 	Vector2(-5, 0),
				 	Vector2(5, 0),
				 ],
				 0.0, 1.0],
			],
		},

		# —— Bow Draw 弓拉 (0.5s) ——
		"bow_draw": {
			"duration": 0.5,
			"keyframes": [
				[0.0,
				 [0.0, -2.0, 0.0, -20.0, 20.0, 0.0, 0.0],
				 [
				 	Vector2(0, 0),
				 	Vector2(0, -16),
				 	Vector2(0, -14),
				 	Vector2(-10, -4),
				 	Vector2(10, -4),
				 	Vector2(-5, 0),
				 	Vector2(5, 0),
				 ],
				 0.0, 1.0],
				[0.45,
				 [-6.0, 6.0, 4.0, -35.0, -55.0, 4.0, -4.0],
				 [
				 	Vector2(-2, 0),
				 	Vector2(-2, -16),
				 	Vector2(0, -14),
				 	Vector2(-6, -6),
				 	Vector2(-4, -10),
				 	Vector2(-8, 4),
				 	Vector2(8, 4),
				 ],
				 -1.0, 1.0],
				[1.0,
				 [0.0, -2.0, 0.0, -30.0, -40.0, 0.0, 0.0],
				 [
				 	Vector2(0, 0),
				 	Vector2(0, -16),
				 	Vector2(0, -14),
				 	Vector2(-6, -6),
				 	Vector2(-4, -10),
				 	Vector2(-5, 0),
				 	Vector2(5, 0),
				 ],
				 0.0, 1.0],
			],
		},

		# —— Cast 法术咏唱 (0.6s) ——
		"cast": {
			"duration": 0.6,
			"keyframes": [
				[0.0,
				 [0.0, 0.0, 0.0, -3.0, 3.0, 0.0, 0.0],
				 [
				 	Vector2(0, 0),
				 	Vector2(0, -16),
				 	Vector2(0, -14),
				 	Vector2(-10, -4),
				 	Vector2(10, -4),
				 	Vector2(-5, 0),
				 	Vector2(5, 0),
				 ],
				 0.0, 1.0],
				[0.6,
				 [0.0, 2.0, 4.0, 110.0, -110.0, -2.0, 2.0],
				 [
				 	Vector2(0, -2),
				 	Vector2(0, -18),
				 	Vector2(2, -14),
				 	Vector2(-4, -22),
				 	Vector2(4, -22),
				 	Vector2(-5, 0),
				 	Vector2(5, 0),
				 ],
				 -2.0, 0.95],
			],
		},

		# —— Dash 冲刺 (0.18s) ——
		"dash": {
			"duration": 0.18,
			"keyframes": [
				[0.0,
				 [0.0, 10.0, 6.0, 45.0, -45.0, -20.0, 20.0],
				 [
				 	Vector2(0, 0),
				 	Vector2(6, -14),
				 	Vector2(6, -14),
				 	Vector2(0, -10),
				 	Vector2(12, -6),
				 	Vector2(-12, 6),
				 	Vector2(12, 6),
				 ],
				 -4.0, 0.96],
				[1.0,
				 [0.0, 10.0, 6.0, 45.0, -45.0, -20.0, 20.0],
				 [
				 	Vector2(0, 0),
				 	Vector2(6, -14),
				 	Vector2(6, -14),
				 	Vector2(0, -10),
				 	Vector2(12, -6),
				 	Vector2(-12, 6),
				 	Vector2(12, 6),
				 ],
				 -4.0, 0.96],
			],
		},

		# —— Hurt 受击 ——
		"hurt": {
			"duration": 0.25,
			"keyframes": [
				[0.0,
				 [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
				 [
				 	Vector2(0, 0),
				 	Vector2(0, -16),
				 	Vector2(0, -14),
				 	Vector2(-10, -4),
				 	Vector2(10, -4),
				 	Vector2(-5, 0),
				 	Vector2(5, 0),
				 ],
				 0.0, 1.0],
				[1.0,
				 [-6.0, -10.0, -8.0, -15.0, 15.0, 0.0, 0.0],
				 [
				 	Vector2(-6, 0),
				 	Vector2(-8, -14),
				 	Vector2(-6, -12),
				 	Vector2(-12, -2),
				 	Vector2(12, -6),
				 	Vector2(-5, 0),
				 	Vector2(5, 0),
				 ],
				 1.0, 1.05],
			],
		},

		# —— Dead 倒地 ——
		"dead": {
			"duration": 0.9,
			"keyframes": [
				[0.0,
				 [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
				 [
				 	Vector2(0, 0),
				 	Vector2(0, -16),
				 	Vector2(0, -14),
				 	Vector2(-10, -4),
				 	Vector2(10, -4),
				 	Vector2(-5, 0),
				 	Vector2(5, 0),
				 ],
				 0.0, 1.0],
				[0.5,
				 [22.5, 45.0, 30.0, 30.0, -20.0, 45.0, -45.0],
				 [
				 	Vector2(4, 0),
				 	Vector2(14, -2),
				 	Vector2(14, -18),
				 	Vector2(-6, -10),
				 	Vector2(12, -4),
				 	Vector2(2, 4),
				 	Vector2(2, 4),
				 ],
				 0.0, 1.0],
				[1.0,
				 [45.0, 90.0, 60.0, 45.0, -30.0, 90.0, -90.0],
				 [
				 	Vector2(8, 0),
				 	Vector2(22, 10),
				 	Vector2(22, -10),
				 	Vector2(-4, -6),
				 	Vector2(14, 0),
				 	Vector2(0, 8),
				 	Vector2(0, 8),
				 ],
				 0.0, 1.0],
			],
		},

		# —— Roll 翻滚 (0.5s) ——
		"roll": {
			"duration": 0.5,
			"keyframes": [
				[0.0,
				 [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
				 [
				 	Vector2(0, 0),
				 	Vector2(0, -16),
				 	Vector2(0, -14),
				 	Vector2(-10, -4),
				 	Vector2(10, -4),
				 	Vector2(-5, 0),
				 	Vector2(5, 0),
				 ],
				 0.0, 1.0],
				[0.25,
				 [180.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
				 [
				 	Vector2(12, 0),
				 	Vector2(0, 0),
				 	Vector2(0, 0),
				 	Vector2(0, 0),
				 	Vector2(0, 0),
				 	Vector2(0, 0),
				 	Vector2(0, 0),
				 ],
				 -10.0, 0.7],
				[0.5,
				 [360.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
				 [
				 	Vector2(24, 0),
				 	Vector2(0, -16),
				 	Vector2(0, -14),
				 	Vector2(-10, -4),
				 	Vector2(10, -4),
				 	Vector2(-5, 0),
				 	Vector2(5, 0),
				 ],
				 0.0, 1.0],
			],
		},

		# —— Jump 起跳 ——
		"jump": {
			"duration": 0.25,
			"keyframes": [
				[0.0,
				 [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
				 [
				 	Vector2(0, 0),
				 	Vector2(0, -16),
				 	Vector2(0, -14),
				 	Vector2(-10, -4),
				 	Vector2(10, -4),
				 	Vector2(-5, 0),
				 	Vector2(5, 0),
				 ],
				 0.0, 1.0],
				[1.0,
				 [0.0, -4.0, 0.0, -20.0, 20.0, -35.0, 35.0],
				 [
				 	Vector2(0, -8),
				 	Vector2(0, -24),
				 	Vector2(0, -22),
				 	Vector2(-8, -8),
				 	Vector2(12, -4),
				 	Vector2(-14, 8),
				 	Vector2(14, 8),
				 ],
				 -2.0, 0.9],
			],
		},

		# —— Cast Focus (蓄力) ——
		"cast_focus": {
			"duration": 1.0,
			"keyframes": [
				[0.0,
				 [0.0, 0.0, 0.0, -3.0, 3.0, 0.0, 0.0],
				 [
				 	Vector2(0, 0),
				 	Vector2(0, -16),
				 	Vector2(0, -14),
				 	Vector2(-10, -4),
				 	Vector2(10, -4),
				 	Vector2(-5, 0),
				 	Vector2(5, 0),
				 ],
				 0.0, 1.0],
				[1.0,
				 [0.0, 4.0, 6.0, 95.0, -95.0, 0.0, 0.0],
				 [
				 	Vector2(0, -4),
				 	Vector2(0, -20),
				 	Vector2(0, -16),
				 	Vector2(-4, -24),
				 	Vector2(4, -24),
				 	Vector2(-5, 0),
				 	Vector2(5, 0),
				 ],
				 -4.0, 0.85],
			],
		},

		# —— Summon Ritual 法阵仪式 ——
		"summon_ritual": {
			"duration": 1.2,
			"keyframes": [
				[0.0,
				 [0.0, 0.0, 0.0, -3.0, 3.0, 0.0, 0.0],
				 [
				 	Vector2(0, 0),
				 	Vector2(0, -16),
				 	Vector2(0, -14),
				 	Vector2(-10, -4),
				 	Vector2(10, -4),
				 	Vector2(-5, 0),
				 	Vector2(5, 0),
				 ],
				 0.0, 1.0],
				[1.0,
				 [0.0, 0.0, 0.0, 135.0, -135.0, -6.0, 6.0],
				 [
				 	Vector2(0, 0),
				 	Vector2(0, -16),
				 	Vector2(0, -14),
				 	Vector2(0, -26),
				 	Vector2(0, -26),
				 	Vector2(-8, 4),
				 	Vector2(8, 4),
				 ],
				 -1.0, 1.08],
				[1.2,
				 [0.0, 0.0, 0.0, 135.0, -135.0, -6.0, 6.0],
				 [
				 	Vector2(0, 0),
				 	Vector2(0, -16),
				 	Vector2(0, -14),
				 	Vector2(0, -26),
				 	Vector2(0, -26),
				 	Vector2(-8, 4),
				 	Vector2(8, 4),
				 ],
				 -1.0, 1.08],
			],
		},

		# —— Block 格挡 ——
		"block": {
			"duration": 0.3,
			"keyframes": [
				[0.0,
				 [0.0, 0.0, 0.0, -3.0, 3.0, 0.0, 0.0],
				 [
				 	Vector2(0, 0),
				 	Vector2(0, -16),
				 	Vector2(0, -14),
				 	Vector2(-10, -4),
				 	Vector2(10, -4),
				 	Vector2(-5, 0),
				 	Vector2(5, 0),
				 ],
				 0.0, 1.0],
				[1.0,
				 [-2.0, -4.0, 2.0, -65.0, 65.0, 0.0, 0.0],
				 [
				 	Vector2(-2, 0),
				 	Vector2(-2, -16),
				 	Vector2(0, -14),
				 	Vector2(-16, -2),
				 	Vector2(16, -2),
				 	Vector2(-5, 0),
				 	Vector2(5, 0),
				 ],
				 0.0, 0.98],
			],
		},

		# —— Crouch 蹲下 ——
		"crouch": {
			"duration": 0.2,
			"keyframes": [
				[0.0,
				 [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
				 [
				 	Vector2(0, 0),
				 	Vector2(0, -16),
				 	Vector2(0, -14),
				 	Vector2(-10, -4),
				 	Vector2(10, -4),
				 	Vector2(-5, 0),
				 	Vector2(5, 0),
				 ],
				 0.0, 1.0],
				[1.0,
				 [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
				 [
				 	Vector2(0, 6),
				 	Vector2(0, -6),
				 	Vector2(0, -10),
				 	Vector2(-8, 0),
				 	Vector2(8, 0),
				 	Vector2(-4, 0),
				 	Vector2(4, 0),
				 ],
				 6.0, 1.0],
			],
		},

		# —— Throw Bomb 抛投 ——
		"throw_bomb": {
			"duration": 0.5,
			"keyframes": [
				[0.0,
				 [0.0, 0.0, 0.0, -3.0, 3.0, 0.0, 0.0],
				 [
				 	Vector2(0, 0),
				 	Vector2(0, -16),
				 	Vector2(0, -14),
				 	Vector2(-10, -4),
				 	Vector2(10, -4),
				 	Vector2(-5, 0),
				 	Vector2(5, 0),
				 ],
				 0.0, 1.0],
				[1.0,
				 [-4.0, -2.0, 0.0, -15.0, -110.0, 4.0, -4.0],
				 [
				 	Vector2(-2, 4),
				 	Vector2(0, -12),
				 	Vector2(0, -14),
				 	Vector2(-12, -2),
				 	Vector2(8, -18),
				 	Vector2(-8, 2),
				 	Vector2(8, 2),
				 ],
				 2.0, 0.98],
			],
		},
	}


# —— AnimState -> 姿势名（映射 SpriteAnim 的 AnimState 枚举到我们的姿势名）——
static func STATE_TO_POSE(state_id: String) -> String:
	var loop_map := {
		"IDLE": "idle",
		"RUN": "run",
		"WALK_CROUCH": "walk",
		"CROUCH": "idle",
		"PRONE": "idle",
		"LURK": "idle",
		"RESURRECTING": "idle",
		"FORCE_READY": "idle",
		"READY": "idle",
		"BLINK": "idle",
	}
	var timeline_map := {
		"ATTACK": "sword_swing",
		"AOE_SWING": "sword_swing",
		"RAPID_STRIKES": "sword_swing",
		"BOW_DRAW": "bow_draw",
		"THROW_BOMB": "throw_bomb",
		"CAST": "cast",
		"CAST_SPELL": "cast",
		"SUMMON_RITUAL": "summon_ritual",
		"CHARGING": "cast_focus",
		"CAST_FOCUS": "cast_focus",
		"DASH": "dash",
		"ROLL": "roll",
		"HURT": "hurt",
		"STAGGER": "hurt",
		"DEAD": "dead",
		"BLOCK": "block",
		"JUMP": "jump",
		"JUMP_FALLING": "jump",
		"JUMP_LAND": "jump",
		"PORTAL": "cast",
		"CELEBRATE": "celebrate",
		"FALL": "jump",
		"SWORD_SWING": "sword_swing",
		"MOUNTED": "idle",
		"DRINK": "cast",
		"CARRY": "idle",
		"SIT": "crouch",
		"TRAP_SET": "crouch",
		"CLIMB": "idle",
		"SWIM": "run",
	}
	if state_id in loop_map:
		return loop_map[state_id]
	if state_id in timeline_map:
		return timeline_map[state_id]
	return "idle"


static func IS_LOOP_POSE(name: String) -> bool:
	return name in LOOP_POSES()


static func IS_TIMELINE_POSE(name: String) -> bool:
	return name in TIMELINE_POSES()
