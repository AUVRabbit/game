; ============================================================
; EventBus.gd — 全局事件总线（发布/订阅模式）
; 解耦各系统之间的通信，避免直接互相引用
; ============================================================
; 用法：
;   EventBus.player_died.connect(_on_player_died)
;   EventBus.emit_signal("player_died", player)
; ============================================================

extends Node
class_name EventBus

# ---------- 玩家事件 ----------
signal player_spawned(player: CharacterBody2D)
signal player_died(player: CharacterBody2D)
signal player_hurt(player: CharacterBody2D, damage: int, source: Node)
signal player_healed(player: CharacterBody2D, amount: int)
signal character_switched(new_char: Node, old_char: Node)

# ---------- 战斗事件 ----------
signal attack_performed(attacker: Node, target: Node)
signal skill_cast(caster: Node, skill_id: String)
signal enemy_died(enemy: Node, killer: Node)
signal item_dropped(item_data: Dictionary, world_pos: Vector2)

# ---------- 世界事件 ----------
signal tile_broken(tile_pos: Vector2i, layer: int)
signal tile_placed(tile_pos: Vector2i, layer: int, tile_data: Dictionary)
signal building_placed(building: Node, grid_pos: Vector2i)
signal building_removed(building: Node)
signal puzzle_triggered(puzzle_id: String, state: bool)
signal level_completed(level_id: String)
signal portal_entered(portal_id: String, target_level: String)

# ---------- 经济事件 ----------
signal item_picked_up(item_data: Dictionary)
signal inventory_changed()
signal gold_changed(new_amount: int, delta: int)
signal item_crafted(result_item: Dictionary)
signal item_sold(item: Dictionary, price: int)

# ---------- 对话/剧情事件 ----------
signal dialogue_started(dialogue_id: String)
signal dialogue_ended(dialogue_id: String)
signal quest_accepted(quest_id: String)
signal quest_completed(quest_id: String)

# ---------- 游戏流程事件 ----------
signal save_completed(slot: int)
signal load_completed(slot: int)
signal roguelite_run_started(run_seed: int)
signal roguelite_run_ended(success: bool, rewards: Dictionary)

# ---------- 便捷发射函数 ----------
func emit(signal_name: String, args: Array = []) -> void:
    if has_signal(signal_name):
        emit_signalv(signal_name, args)
    else:
        push_warning("[EventBus] 未知信号: %s" % signal_name)
