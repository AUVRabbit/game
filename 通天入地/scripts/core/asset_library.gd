# ============================================================
# AssetLibrary — 素材索引（按逻辑 id 取贴图，带缓存）
# id 规则：skill_xxx / item_xxx / portrait_xxx / passive_xxx / vfx_xxx / enemy_xxx / sprite_xxx / ground_xxx
# ============================================================

extends RefCounted
class_name AssetLibrary

static var _cache: Dictionary = {}

static func path_for(asset_id: String) -> String:
	if asset_id.begins_with("skill_"):
		return "res://assets/icons/skill/%s.png" % asset_id.substr(6)
	if asset_id.begins_with("item_"):
		return "res://assets/icons/item/%s.png" % asset_id.substr(5)
	if asset_id.begins_with("portrait_"):
		return "res://assets/portraits/%s.png" % asset_id.substr(9)
	if asset_id.begins_with("passive_"):
		return "res://assets/icons/passive/%s.png" % asset_id.substr(8)
	if asset_id.begins_with("vfx_"):
		return "res://assets/vfx/%s.png" % asset_id.substr(4)
	if asset_id.begins_with("enemy_"):
		return "res://assets/sprites/%s.png" % asset_id
	if asset_id.begins_with("sprite_"):
		return "res://assets/sprites/world/%s.png" % asset_id.substr(7)
	if asset_id.begins_with("ground_"):
		return "res://assets/ground/%s.png" % asset_id.substr(6)
	return "res://assets/icons/%s.png" % asset_id

static func has(asset_id: String) -> bool:
	return ResourceLoader.exists(path_for(asset_id))

static func texture(asset_id: String) -> Texture2D:
	if asset_id == "":
		return null
	if _cache.has(asset_id):
		return _cache[asset_id]
	var path := path_for(asset_id)
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	_cache[asset_id] = tex
	return tex

static func clear_cache() -> void:
	_cache.clear()
