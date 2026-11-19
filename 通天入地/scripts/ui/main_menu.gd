# ============================================================
# MainMenu.gd — 主菜单逻辑
# ============================================================

extends Control
class_name MainMenu

@onready var btn_new_game: Button = $ButtonContainer/BtnNewGame
@onready var btn_continue: Button = $ButtonContainer/BtnContinue
@onready var btn_settings: Button = $ButtonContainer/BtnSettings
@onready var btn_exit: Button = $ButtonContainer/BtnExit

func _ready() -> void:
    btn_new_game.pressed.connect(_on_new_game)
    btn_continue.pressed.connect(_on_continue)
    btn_settings.pressed.connect(_on_settings)
    btn_exit.pressed.connect(_on_exit)
    # 无存档时禁用继续游戏按钮
    btn_continue.disabled = not SaveManager or not SaveManager.has_save(0)

func _on_new_game() -> void:
    print("[MainMenu] 开始新游戏")
    if GameManager:
        GameManager.enter_main_world()

func _on_continue() -> void:
    print("[MainMenu] 继续游戏")
    if SaveManager and GameManager:
        SaveManager.load_game(0)
        GameManager.enter_main_world()

func _on_settings() -> void:
    print("[MainMenu] 打开设置")
    # TODO: 打开设置面板

func _on_exit() -> void:
    get_tree().quit()
