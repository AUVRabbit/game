# ============================================================
# EventBus — 全局事件总线（发布 / 订阅）
# 用法：
#   EventBus.player_died.connect(_on_player_died)
#   EventBus.emit_event("player_died", [player])
# ============================================================

extends Node

# ---------- 玩家 ----------
signal player_spawned(player: Node)
signal player_died(player: Node)
signal player_hurt(player: Node, damage: int, source: Node)
signal player_healed(player: Node, amount: int)
signal player_leveled_up(player: Node, new_level: int)
signal character_switched(new_char: Node, old_char: Node)

# ---------- 战斗 ----------
signal attack_performed(attacker: Node, target: Node)
signal skill_cast(caster: Node, skill_id: String)
signal enemy_died(enemy: Node, killer: Node)
signal item_dropped(item_data: Dictionary, world_pos: Vector2)

# ---------- 世界 ----------
signal tile_broken(tile_pos: Vector2i, layer: int)
signal tile_placed(tile_pos: Vector2i, layer: int, tile_data: Dictionary)
signal building_placed(building: Node, grid_pos: Vector2i)
signal building_removed(building: Node)
signal puzzle_triggered(puzzle_id: String, state: bool)
signal level_completed(level_id: String)
signal portal_entered(portal_id: String, target_level: String)

# ---------- 经济 ----------
signal item_picked_up(item_data: Dictionary)
signal inventory_changed()
signal gold_changed(new_amount: int, delta: int)
signal item_crafted(result_item: Dictionary)
signal item_sold(item: Dictionary, price: int)

# ---------- 剧情 ----------
signal dialogue_started(dialogue_id: String)
signal dialogue_ended(dialogue_id: String)
signal quest_accepted(quest_id: String)
signal quest_updated(quest_id: String)
signal quest_completed(quest_id: String)

# ---------- 朋克改造 ----------
signal punk_applied(class_id: String, slot: String, part_id: String)
signal punk_removed(class_id: String, slot: String, part_id: String)
signal punk_style_changed(class_id: String, style_id: String)

# ---------- 技能树 / 职业专职 ----------
signal skill_node_unlocked(class_id: String, node_id: String)
signal skill_tree_reset(class_id: String)
signal specialization_chosen(class_id: String, spec_id: String)

# ---------- 流程 ----------
signal toast_requested(text: String)
signal save_completed(slot: int)
signal load_completed(slot: int)
signal roguelite_run_started(run_seed: int)
signal roguelite_run_ended(success: bool, rewards: Dictionary)

# ---------- 动态发射 ----------
func emit_event(signal_name: String, args: Array = []) -> void:
	if not has_signal(signal_name):
		push_warning("[EventBus] 未知信号: %s" % signal_name)
		return
	var call_args: Array = [signal_name]
	call_args.append_array(args)
	emit_signal.callv(call_args)

func notify(text: String) -> void:
	toast_requested.emit(text)
