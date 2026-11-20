# ============================================================
# AudioManager — 音频管理
# 音频资源缺失时静默降级（不报错），便于无素材阶段开发
# 约定目录：res://audio/bgm/<name>.ogg，res://audio/sfx/<name>.wav
# ============================================================

extends Node

const SFX_POOL_SIZE := 8

var bgm_player: AudioStreamPlayer
var sfx_players: Array = []
var master_volume: float = 0.8

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGM"
	bgm_player.volume_db = linear_to_db(master_volume)
	add_child(bgm_player)
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.name = "SFX%d" % i
		p.volume_db = linear_to_db(master_volume)
		add_child(p)
		sfx_players.append(p)

func play_bgm(track_name: String) -> void:
	var stream := _load_stream("res://audio/bgm/" + track_name)
	if stream == null:
		return
	if bgm_player.stream == stream and bgm_player.playing:
		return
	bgm_player.stream = stream
	bgm_player.play()

func stop_bgm() -> void:
	if bgm_player:
		bgm_player.stop()

func play_sfx(sfx_name: String) -> void:
	var stream := _load_stream("res://audio/sfx/" + sfx_name)
	if stream == null:
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = stream
			p.play()
			return
	if sfx_players.size() > 0:
		sfx_players[0].stream = stream
		sfx_players[0].play()

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	var db := linear_to_db(maxf(master_volume, 0.0001))
	if bgm_player:
		bgm_player.volume_db = db
	for p in sfx_players:
		p.volume_db = db

func _load_stream(base_path: String) -> AudioStream:
	for ext in [".ogg", ".wav", ".mp3"]:
		if ResourceLoader.exists(base_path + ext):
			var res := load(base_path + ext)
			if res is AudioStream:
				return res
	return null
