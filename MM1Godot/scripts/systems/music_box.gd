class_name MusicBoxScene
extends SimpleScene

var tracks: Array = []


func _ready() -> void:
	title = "音乐盒"
	tracks = _load_tracks()
	super._ready()


func _load_tracks() -> Array:
	var table = DB.mm.get("data_musiclist", {})
	var raw = table.get("1", []) if table is Dictionary else []
	var out: Array = []
	if raw is Array:
		for entry in raw:
			if entry is Array and entry.size() >= 2:
				out.append({"label": str(entry[0]), "file": str(entry[1])})
	elif raw is Dictionary:
		for key in raw.keys():
			var entry2 = raw[key]
			if entry2 is Array and entry2.size() >= 2:
				out.append({"label": str(entry2[0]), "file": str(entry2[1])})
	return out


func build_entries() -> Array:
	return tracks.duplicate()


func info_text() -> String:
	return "选择曲目"


func on_confirm(index: int) -> void:
	if index >= tracks.size():
		return
	var file := str(tracks[index].get("file", ""))
	if file.is_empty():
		return
	Audio.play_bgm(file.get_basename(), 100)
	show_notice("正在播放：%s" % str(tracks[index].get("label", "")))
