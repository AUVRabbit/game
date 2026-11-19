# ============================================================
# Pickup — 地面掉落物
# ============================================================

extends Area2D

var item_id: String = ""
var quantity: int = 1
var color: Color = Color(1, 1, 1)
var bob_time: float = 0.0

func _ready() -> void:
	add_to_group("pickups")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var tpl: Dictionary = DataManager.get_item(item_id) if DataManager else {}
	color = Color.from_string(str(tpl.get("color", "#ffffff")), Color.WHITE)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _process(delta: float) -> void:
	bob_time += delta
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if GameManager == null or GameManager.inventory == null:
		return
	if GameManager.inventory.add_item(item_id, quantity):
		var tpl := DataManager.get_item(item_id) if DataManager else {}
		EventBus.item_picked_up.emit({ "id": item_id, "quantity": quantity })
		EventBus.notify("拾取：%s ×%d" % [str(tpl.get("name", item_id)), quantity])
		AudioManager.play_sfx("pickup")
		queue_free()

func _draw() -> void:
	var bob := sin(bob_time * 3.0) * 3.0
	var pos := Vector2(0, bob)
	draw_circle(pos, 12.0, Color(color.r, color.g, color.b, 0.18))
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(0, -9), pos + Vector2(9, 0), pos + Vector2(0, 9), pos + Vector2(-9, 0)
	]), color)
