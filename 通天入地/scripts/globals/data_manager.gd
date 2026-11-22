# ============================================================
# DataManager — 全局数据表（物品 / 职业 / 配方 / 任务 / 对话）
# 单一数据入口，所有系统通过它读取 JSON 配置
# 注意：AutoLoad 脚本不声明 class_name（Godot 4.7 限制）
# ============================================================

extends Node

var items: Dictionary = {}
var classes: Dictionary = {}
var class_growth: Dictionary = {}
var recipes: Array = []
var quests: Dictionary = {}
var dialogues: Dictionary = {}
var punk_styles: Array = []
var punk_parts: Array = []
var punk_part_by_id: Dictionary = {}
var punk_build_decorations: Array = []
var class_style_bindings: Dictionary = {}
var style_bonus_match: float = 0.15
var skill_trees: Dictionary = {}
var skill_points_per_level: int = 1
var skill_starting_points: int = 1
var specializations: Dictionary = {}
# ---------- 四阶进阶（1转流派 / 2转融合 / 3转变身 / 4转超脱） ----------
var styles: Dictionary = {}
var class_styles: Dictionary = {}
var style_specs: Dictionary = {}
var style_apexes: Dictionary = {}
var class_fusions: Dictionary = {}
var class_ascensions: Dictionary = {}
var class_transcends: Dictionary = {}
var borrow_pool: Dictionary = {}
var tree_layout: Dictionary = {}
var fusion_slot_rules: Dictionary = {}
var _ability_index: Dictionary = {}

func _ready() -> void:
	_load_all()

func _load_all() -> void:
	var d_items := _read_json("res://data/items.json")
	if d_items.has("items"):
		items = d_items["items"]

	var d_classes := _read_json("res://data/classes.json")
	if d_classes.has("classes"):
		classes = d_classes["classes"]
	if d_classes.has("growth"):
		class_growth = d_classes["growth"]

	var d_recipes := _read_json("res://data/recipes.json")
	if d_recipes.has("recipes") and typeof(d_recipes["recipes"]) == TYPE_ARRAY:
		recipes = d_recipes["recipes"]

	var d_quests := _read_json("res://data/quests.json")
	if d_quests.has("quests"):
		quests = d_quests["quests"]

	var d_dialogue := _read_json("res://data/dialogue.json")
	if d_dialogue.has("dialogues"):
		dialogues = d_dialogue["dialogues"]

	var d_punk := _read_json("res://data/punk_parts.json")
	if d_punk.has("styles") and typeof(d_punk["styles"]) == TYPE_ARRAY:
		punk_styles = d_punk["styles"]
	if d_punk.has("parts") and typeof(d_punk["parts"]) == TYPE_ARRAY:
		punk_parts = d_punk["parts"]
		for p in punk_parts:
			var pid: String = str(p.get("id", ""))
			if pid != "":
				punk_part_by_id[pid] = p
	if d_punk.has("build_decorations") and typeof(d_punk["build_decorations"]) == TYPE_ARRAY:
		punk_build_decorations = d_punk["build_decorations"]
	if d_punk.has("class_style_bindings"):
		class_style_bindings = d_punk["class_style_bindings"]
	if d_punk.has("style_bonus_when_matched"):
		style_bonus_match = float(d_punk["style_bonus_when_matched"])

	var d_trees := _read_json("res://data/skill_trees.json")
	if d_trees.has("trees"):
		skill_trees = d_trees["trees"]
	skill_points_per_level = int(d_trees.get("points_per_level", 1))
	skill_starting_points = int(d_trees.get("starting_points", 1))
	if d_trees.has("layout"):
		tree_layout = d_trees["layout"]
	if d_trees.has("fusion_slots"):
		fusion_slot_rules = d_trees["fusion_slots"]

	var d_styles := _read_json("res://data/style_branches.json")
	if d_styles.has("styles"):
		styles = d_styles["styles"]
		class_styles = d_styles.get("class_styles", {})
		style_specs = d_styles.get("specs", {})
		style_apexes = d_styles.get("apexes", {})
		class_fusions = d_styles.get("class_fusions", {})
		class_ascensions = d_styles.get("ascensions", {})
		class_transcends = d_styles.get("transcends", {})
		borrow_pool = d_styles.get("borrow_pool", {})
		_ability_index.clear()

	var d_spec := _read_json("res://data/specializations.json")
	if d_spec.has("specializations"):
		specializations = d_spec["specializations"]

	print("[DataManager] 数据加载完成：物品 %d / 职业 %d / 配方 %d / 任务 %d / 对话 %d / 朋克部件 %d / 技能树 %d / 流派 %d" % [
		items.size(), classes.size(), recipes.size(), quests.size(), dialogues.size(), punk_parts.size(), skill_trees.size(), styles.size()
	])

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("[DataManager] 缺少数据文件：%s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[DataManager] 无法打开：%s" % path)
		return {}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("[DataManager] JSON 解析失败 %s：%s (行 %d)" % [path, json.get_error_message(), json.get_error_line()])
		return {}
	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("[DataManager] JSON 根节点不是对象：%s" % path)
		return {}
	return json.data

# ---------- 物品 ----------
func get_item(item_id: String) -> Dictionary:
	return items.get(item_id, {})

func has_item_def(item_id: String) -> bool:
	return items.has(item_id)

func get_items_by_type(type_name: String) -> Array:
	var result: Array = []
	for key in items.keys():
		var it: Dictionary = items[key]
		if str(it.get("type", "")) == type_name:
			result.append(it)
	return result

# ---------- 职业 ----------
func get_class_data(class_id: String) -> Dictionary:
	return classes.get(class_id, {})

func get_all_class_ids() -> Array:
	return classes.keys()

func get_class_growth() -> Dictionary:
	return class_growth

# ---------- 配方 ----------
func get_recipe(recipe_id: String) -> Dictionary:
	for r in recipes:
		if str(r.get("id", "")) == recipe_id:
			return r
	return {}

func get_recipes() -> Array:
	return recipes

# ---------- 任务 ----------
func get_quest(quest_id: String) -> Dictionary:
	return quests.get(quest_id, {})

# ---------- 对话 ----------
func get_dialogue(dialogue_id: String) -> Dictionary:
	return dialogues.get(dialogue_id, {})

# ---------- 朋克改造 ----------
func get_punk_part(part_id: String) -> Dictionary:
	return punk_part_by_id.get(part_id, {})

func get_all_punk_parts() -> Array:
	return punk_parts

func get_punk_parts_by_style(style_id: String) -> Array:
	var result: Array = []
	for p in punk_parts:
		if str(p.get("style", "")) == style_id:
			result.append(p)
	return result

func get_punk_styles() -> Array:
	return punk_styles

func get_punk_style_color(style_id: String) -> Color:
	for s in punk_styles:
		if str(s.get("id", "")) == style_id:
			return Color.from_string(str(s.get("color", "#ffffff")), Color.WHITE)
	return Color.WHITE

func get_class_allowed_styles(class_id: String) -> Array:
	return class_style_bindings.get(class_id, [])

func get_style_bonus_match() -> float:
	return style_bonus_match

# ---------- 技能树 / 职业专职 ----------
func get_skill_tree(class_id: String) -> Dictionary:
	return skill_trees.get(class_id, {})

func get_skill_tree_nodes(class_id: String) -> Array:
	var tree: Dictionary = get_skill_tree(class_id)
	return tree.get("nodes", []) if tree.has("nodes") else []

func get_skill_node(class_id: String, node_id: String) -> Dictionary:
	for n in get_skill_tree_nodes(class_id):
		if str(n.get("id", "")) == node_id:
			return n
	return {}

func get_specializations(class_id: String) -> Array:
	return specializations.get(class_id, [])

func get_specialization_data(class_id: String, spec_id: String) -> Dictionary:
	for s in get_specializations(class_id):
		if str(s.get("id", "")) == spec_id:
			return s
	return {}

# ---------- 四阶进阶 ----------
func get_style(style_id: String) -> Dictionary:
	return styles.get(style_id, {})

func get_class_style_ids(class_id: String) -> Array:
	return class_styles.get(class_id, [])

func get_style_specs_at(style_id: String) -> Array:
	return style_specs.get(style_id, [])

func get_style_apex(style_id: String) -> Dictionary:
	return style_apexes.get(style_id, {})

func get_class_fusion(class_id: String) -> Dictionary:
	return class_fusions.get(class_id, {})

func get_class_ascension(class_id: String) -> Dictionary:
	return class_ascensions.get(class_id, {})

func get_class_transcend(class_id: String) -> Dictionary:
	return class_transcends.get(class_id, {})

func get_borrow_pool() -> Dictionary:
	return borrow_pool

func get_borrow(source_id: String) -> Dictionary:
	return borrow_pool.get(source_id, {})

func get_class_source(class_id: String) -> String:
	return str(get_class_data(class_id).get("source", ""))

func get_tree_layout() -> Dictionary:
	return tree_layout

func get_fusion_slot_rules() -> Dictionary:
	return fusion_slot_rules

func get_ability(ability_id: String) -> Dictionary:
	if _ability_index.is_empty():
		_build_ability_index()
	return _ability_index.get(ability_id, {})

func _build_ability_index() -> void:
	_ability_index.clear()
	for style_id in styles.keys():
		var style: Dictionary = styles[style_id]
		for sk in style.get("skills", []):
			_ability_index[str(sk.get("id", ""))] = sk
		for spec in style_specs.get(style_id, []):
			_ability_index[str(spec.get("id", ""))] = spec.get("active", {})
		var apex: Dictionary = style_apexes.get(style_id, {})
		if not apex.is_empty():
			_ability_index[str(apex.get("id", ""))] = apex.get("active", {})
	for cid in class_fusions.keys():
		var f: Dictionary = class_fusions[cid]
		_ability_index[str(f.get("id", ""))] = f.get("active", {})
	for cid in class_ascensions.keys():
		var a: Dictionary = class_ascensions[cid]
		_ability_index[str(a.get("id", ""))] = a.get("active", {})
	for cid in class_transcends.keys():
		var t: Dictionary = class_transcends[cid]
		_ability_index[str(t.get("id", ""))] = t.get("active", {})
	for src in borrow_pool.keys():
		var b: Dictionary = borrow_pool[src]
		_ability_index[str(b.get("id", ""))] = b.get("active", {})
