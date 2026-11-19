# ============================================================
# main.gd — 引导入口：启动主菜单
# ============================================================

extends Node

func _ready() -> void:
	randomize()
	if GameManager:
		GameManager.enter_main_menu()
