# ============================================================
# BuildBlock — 建造方块实体（等距菱形 + 可选碰撞）
# ============================================================

extends Node2D
class_name BuildBlock

const SPRITE_MAP := {
	"grass": "sprite_block_grass",
	"stone_block": "sprite_block_stone_block",
	"wood_block": "sprite_block_wood_block",
	"wall": "sprite_block_wall",
	"fence": "sprite_block_fence",
	"torch": "sprite_block_torch",
	"bed": "sprite_block_bed",
	"chest": "sprite_block_chest",
}

var block_id: String = "stone_block"
var grid_pos: Vector2i = Vector2i.ZERO
var color: Color = Color(0.5, 0.5, 0.55)
var collidable: bool = false
var configured: bool = false
var sprite: Sprite2D = null

func setup(new_block_id: String, hovered: bool = false) -> void:
	block_id = new_block_id
	var tpl: Dictionary = DataManager.get_item(block_id) if DataManager else {}
	color = Color.from_string(str(tpl.get("color", "#777777")), Color(0.5, 0.5, 0.55))
	collidable = bool(tpl.get("collidable", false))
	modulate = Color(1.0, 1.0, 1.0, 0.62) if hovered else Color.WHITE
	configured = true

func _ready() -> void:
	if not configured:
		setup(block_id, false)
	_load_sprite()
	if not sprite:
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([
			Vector2(0, -18), Vector2(32, 0), Vector2(0, 18), Vector2(-32, 0)
		])
		poly.color = color
		add_child(poly)
		var top := Polygon2D.new()
		top.polygon = PackedVector2Array([
			Vector2(0, -18), Vector2(32, 0), Vector2(0, -8), Vector2(-32, 0)
		])
		top.color = Color(color.r * 1.25, color.g * 1.25, color.b * 1.25, 1.0)
		add_child(top)
	if collidable:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(56, 28)
		shape.shape = rect
		body.add_child(shape)
		add_child(body)
	queue_redraw()

func _load_sprite() -> void:
	var asset_id: String = str(SPRITE_MAP.get(block_id, ""))
	if asset_id == "":
		return
	var tex: Texture2D = AssetLibrary.texture(asset_id)
	if tex == null:
		return
	sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.scale = Vector2.ONE * 0.46
	add_child(sprite)

func set_hovered(hovered: bool) -> void:
	modulate = Color(1.0, 1.0, 1.0, 0.62) if hovered else Color.WHITE
