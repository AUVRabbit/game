# ============================================================
# NPC — 可交互剧情 NPC（对话 + 接取任务）
# ============================================================

extends Area2D
class_name DialogueNPC

@export var npc_name: String = "村民"
@export var dialogue_id: String = ""
@export var quest_id: String = ""
@export var npc_color: Color = Color(0.85, 0.7, 0.35)

var label: Label = null

func _ready() -> void:
	add_to_group("interactables")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 22.0
	shape.shape = circle
	add_child(shape)
	label = Label.new()
	label.text = npc_name
	label.position = Vector2(-60, -54)
	label.size = Vector2(120, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	add_child(label)
	queue_redraw()

func interact(_player: Node) -> void:
	var dialogue: Dictionary = DataManager.get_dialogue(dialogue_id) if DataManager else {}
	var lines: Array = dialogue.get("lines", ["……"])
	var shown_name := str(dialogue.get("name", npc_name))
	var boxes := get_tree().get_nodes_in_group("dialogue_box")
	if boxes.is_empty():
		for line in lines:
			EventBus.notify(line)
		_after_dialogue()
		return
	var box = boxes[0]
	if box.has_method("show_dialogue"):
		box.show_dialogue(shown_name, lines, Callable(self, "_after_dialogue"))

func _after_dialogue() -> void:
	if quest_id != "" and QuestManager:
		QuestManager.start_quest(quest_id)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 20.0, Color(npc_color.r, npc_color.g, npc_color.b, 0.2))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -18), Vector2(16, 0), Vector2(0, 18), Vector2(-16, 0)
	]), npc_color)
	draw_circle(Vector2(0, -6), 5.0, Color(0.15, 0.12, 0.1))
