extends RefCounted
# 预加载核心 class_name 脚本，解决 Godot 4 中循环 class_name 引用导致的解析失败问题。
# 只 preload 游戏启动时必须的脚本；Shops / UI / Systems 按需加载。

const _GameActor := preload("res://scripts/core/game_actor.gd")
const _GameTank := preload("res://scripts/core/game_tank.gd")
const _GameParty := preload("res://scripts/core/party.gd")
const _GamePlayer := preload("res://scripts/core/game_player.gd")
const _GameEvent := preload("res://scripts/core/game_event.gd")
const _MapScene := preload("res://scripts/core/map_scene.gd")
const _TileLayer := preload("res://scripts/core/tile_layer.gd")
const _Interpreter := preload("res://scripts/core/interpreter.gd")
const _ScriptBridge := preload("res://scripts/core/script_bridge.gd")
