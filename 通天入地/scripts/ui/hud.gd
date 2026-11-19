# ============================================================
# HUD.gd — 游戏内 HUD 逻辑
# 实时更新 HP/MP/EXP/金币/暂停状态
# ============================================================

extends CanvasLayer
class_name HUD

@onready var name_label: Label = $TopLeft/VBox/NameLabel
@onready var hp_bar: ProgressBar = $TopLeft/VBox/HPBar
@onready var hp_label: Label = $TopLeft/VBox/HPLabel
@onready var mp_bar: ProgressBar = $TopLeft/VBox/MPBar
@onready var mp_label: Label = $TopLeft/VBox/MPLabel
@onready var gold_label: Label = $TopRight/GoldLabel
@onready var exp_label: Label = $TopRight/ExpLabel
@onready var input_mode_label: Label = $InputMode
@onready var pause_overlay: ColorRect = $PauseOverlay
@onready var pause_label: Label = $PauseOverlay/PauseLabel

var pause_btn_last_pressed: bool = false

func _ready() -> void:
    # 订阅 GameManager 的暂停信号
    if GameManager:
        GameManager.game_paused.connect(_on_game_paused)
        GameManager.game_resumed.connect(_on_game_resumed)
    # 订阅输入模式变化
    if InputManager:
        InputManager.input_mode_changed.connect(_on_input_mode_changed)
        _on_input_mode_changed(InputManager.mode_name())

func _process(_delta: float) -> void:
    # 实时刷新 HUD
    if GameManager and GameManager.active_player:
        var char_data = GameManager.active_player.get_node_or_null("CharacterData")
        if char_data:
            name_label.text = "%s Lv.%d" % [char_data.class_display_name, char_data.level]
            hp_bar.max_value = char_data.max_hp
            hp_bar.value = char_data.hp
            hp_label.text = "HP %d/%d" % [char_data.hp, char_data.max_hp]
            mp_bar.max_value = char_data.max_mp
            mp_bar.value = char_data.mp
            mp_label.text = "MP %d/%d" % [char_data.mp, char_data.max_mp]
            gold_label.text = "💰 %d" % char_data.gold
            exp_label.text = "EXP %d/%d" % [char_data.exp, char_data.exp_to_next]

func _on_input_mode_changed(mode: String) -> void:
    match mode:
        "keyboard": input_mode_label.text = "⌨ 键鼠"
        "gamepad":  input_mode_label.text = "🎮 手柄"
        "touch":    input_mode_label.text = "📱 触屏"
        _:          input_mode_label.text = mode

func _on_game_paused() -> void:
    pause_overlay.visible = true
    pause_label.visible = true

func _on_game_resumed() -> void:
    pause_overlay.visible = false
    pause_label.visible = false
