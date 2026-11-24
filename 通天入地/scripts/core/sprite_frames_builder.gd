# ============================================================
# SpriteFramesBuilder — 从 sheet PNG 动态构建 SpriteFrames
#
# 签名: add_frame(animation, texture, duration=1.0, atlast_id=-1)
#   → 不支持 region！用 AtlasTexture 手动切 frame
#
# 用法:
#   var frames := SpriteFramesBuilder.from_asset_id(...)
#   anim.sprite_frames = frames
#   anim.play("idle")
# ============================================================

extends RefCounted
class_name SpriteFramesBuilder

static func _load_tex(path: String) -> Texture2D:
	var res := load(path)
	if res == null:
		return null
	return res

static func _slice_sheet(sheet: Texture2D, frame_w: int, frame_h: int, count: int) -> Array[AtlasTexture]:
	var out: Array[AtlasTexture] = []
	if sheet == null:
		return out
	var sheet_size := sheet.get_size()
	for i in range(count):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * frame_w, 0, frame_w, frame_h)
		if i * frame_w >= sheet_size.x:
			break
		out.append(atlas)
	return out

static func from_images(
	images: Array,
	actions: Array,
	frame_counts: Array,
	fps: Array,
	frame_w: int,
	frame_h: int
) -> SpriteFrames:
	var frames := SpriteFrames.new()
	for i in range(actions.size()):
		var action_name: String = str(actions[i])
		var frame_count: int = int(frame_counts[i]) if i < frame_counts.size() else 4
		var action_fps: int = int(fps[i]) if i < fps.size() else 8
		var path: String = str(images[i]) if i < images.size() else ""
		var tex := _load_tex(path)
		if tex == null:
			continue
		var atlases := _slice_sheet(tex, frame_w, frame_h, frame_count)
		if atlases.is_empty():
			continue
		frames.add_animation(action_name)
		frames.set_animation_loop(action_name, action_name == "idle" or action_name == "walk")
		frames.set_animation_speed(action_name, action_fps * 0.1)
		for a in atlases:
			frames.add_frame(action_name, a, 1.0)
	return frames

static func from_asset_id(asset_id: String, frame_w: int, frame_h: int, actions: Array, frame_counts: Array, fps: Array) -> SpriteFrames:
	var asset_paths := [
		"res://assets/sprites/%s_%s.png",
		"res://assets/sprites/world/%s_%s.png",
	]
	var images: Array = []
	for action in actions:
		var found: String = ""
		for tmpl in asset_paths:
			var tmpl_str: String = str(tmpl)
			var p: String = tmpl_str % [asset_id, action]
			if ResourceLoader.exists(p):
				found = p
				break
		images.append(found)
	return from_images(images, actions, frame_counts, fps, frame_w, frame_h)
