extends Node
## BGM / ME / SE playback (replaces Audio module of RGSS).

const BGM_DIR := "res://assets/audio/BGM/"
const ME_DIR := "res://assets/audio/ME/"
const SE_DIR := "res://assets/audio/SE/"
const EXTENSIONS := [".ogg", ".mp3", ".wav"]

var _bgm: AudioStreamPlayer
var _me: AudioStreamPlayer
var _se_players: Array[AudioStreamPlayer] = []
var _se_index := 0
var _current_bgm := ""
var _fade_tween: Tween


func _ready() -> void:
	_bgm = _make_player(-8.0)
	_me = _make_player(-6.0)
	for i in range(8):
		_se_players.append(_make_player(0.0))


func _make_player(volume_db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.volume_db = volume_db
	add_child(p)
	return p


func _find(dir: String, name: String) -> String:
	if name.is_empty():
		return ""
	var stripped := name.get_basename()
	for ext in EXTENSIONS:
		var path: String = dir + stripped + str(ext)
		if ResourceLoader.exists(path):
			return path
	return ""


func play_bgm(name: String, volume: int = 100, _pitch: int = 100) -> void:
	if _current_bgm == name and _bgm.playing:
		return
	_stop_bgm_internal()
	var path := _find(BGM_DIR, name)
	if path.is_empty():
		return
	var stream: AudioStream = load(path)
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamMP3:
		stream.loop = true
	_bgm.stream = stream
	_bgm.volume_db = linear_to_db(max(volume, 1) / 100.0) - 6.0
	_bgm.play()
	_current_bgm = name


func _stop_bgm_internal() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_bgm.stop()
	_current_bgm = ""


func stop_bgm() -> void:
	_stop_bgm_internal()


func fade_bgm(time: float = 0.8) -> void:
	if not _bgm.playing:
		return
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_bgm, "volume_db", -40.0, time)
	_fade_tween.tween_callback(func(): _bgm.stop(); _current_bgm = "")


func play_me(name: String, volume: int = 100, _pitch: int = 100) -> void:
	var path := _find(ME_DIR, name)
	if path.is_empty():
		return
	_me.stream = load(path)
	_me.volume_db = linear_to_db(max(volume, 1) / 100.0) - 4.0
	_me.play()


func stop_me() -> void:
	_me.stop()


func play_se(name: String, volume: int = 100, pitch: int = 100) -> void:
	var path := _find(SE_DIR, name)
	if path.is_empty():
		return
	var p := _se_players[_se_index]
	_se_index = (_se_index + 1) % _se_players.size()
	p.stream = load(path)
	p.volume_db = linear_to_db(max(volume, 1) / 100.0)
	p.pitch_scale = clampf(pitch / 100.0, 0.5, 2.0)
	p.play()


func cursor() -> void:
	play_se("mm-cursor", 80)


func decision() -> void:
	play_se("mm-ok", 90)


func cancel() -> void:
	play_se("mm-ok", 70, 80)


func buzzer() -> void:
	play_se("mm-ok", 70, 60)
