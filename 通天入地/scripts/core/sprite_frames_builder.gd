# ============================================================
# SpriteFramesBuilder — 从 sheet PNG 动态构建 SpriteFrames
#
# 用法:
#   var frames := SpriteFramesBuilder.from_sheet(
#       preload("res://assets/sprites/enemy_slime_sheet.png"),
#       frame_w=96, frame_h=96,
#       actions=["idle", "walk", "attack", "hit"],
#       frame_counts=[4, 4, 3, 2],
#       fps=[6, 10, 12, 14]
#   )
#   var anim := AnimatedSprite2D.new()
#   anim.sprite_frames = frames
#   anim.play("idle")
# ============================================================

extends RefCounted
class_name SpriteFramesBuilder

static func _load_tex(path: String) -> Texture2D:
	var res := load(path)
	if res == null:
		return null
	if res is CompressedTexture2D and not res.is_ready():
		# 强制等待
		res.load()
	return res

static func from_images(
	images: Array[String],
	actions: Array[String],
	frame_counts: Array[int],
	fps: Array[int]
) -> SpriteFrames:
	"""
	从多张独立 sheet 构建（每个 action 一张 sheet）。
	images:  每个 action 对应的 sheet PNG 路径
	actions: ["idle", "walk", "attack", "hit"]
	frame_counts: 每个 action 的帧数（比如 [4, 4, 3, 2]）
	fps:     每个 action 的 fps（比如 [6, 10, 12, 14]）
	"""
	var frames := SpriteFrames.new()
	frames.animation_speed = 1.0
	frames.optimize = false
	
	for i in range(actions.size()):
		var action_name: String = actions[i]
		var frame_count: int = frame_counts[i] if i < frame_counts.size() else 4
		var action_fps: int = fps[i] if i < fps.size() else 8
		var path: String = images[i] if i < images.size() else ""
		
		var tex := _load_tex(path)
		if tex == null:
			continue
		
		var tex_size := tex.get_size()
		var fw: int = int(tex_size.x / frame_count)
		var fh: int = int(tex_size.y)
		
		frames.add_animation(action_name)
		frames.set_animation_loop(action_name, action_name == "idle" or action_name == "walk")
		frames.set_animation_speed(action_name, action_fps * 0.1)  # Godot 4 速度以倍速计
		
		for f in range(frame_count):
			var region := Rect2(f * fw, 0, fw, fh)
			frames.add_frame(action_name, tex, region, Vector2.ZERO)
	
	return frames

static func from_asset_id(asset_id: String, frame_w: int, frame_h: int, actions: Array[String], frame_counts: Array[int], fps: Array[int]) -> SpriteFrames:
	"""
	统一入口：asset_id 是 object 的基础名字（如 "enemy_slime" / "minion_archer" / "player_warrior"）
	自动查找 res://assets/sprites/{asset_id}_{action}.png 或 res://assets/sprites/world/{asset_id}_{action}.png
	"""
	var asset_paths := [
		"res://assets/sprites/%s_%s.png",
		"res://assets/sprites/world/%s_%s.png",
	]
	var images: Array[String] = []
	for action in actions:
		var found: String = ""
		for tmpl in asset_paths:
			var p := tmpl % [asset_id, action]
			if ResourceLoader.exists(p):
				found = p
				break
		images.append(found)
	
	return from_images(images, actions, frame_counts, fps)
