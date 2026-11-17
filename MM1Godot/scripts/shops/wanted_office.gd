class_name WantedOfficeScene
extends SimpleScene

const REWARD := 2000


func _ready() -> void:
	title = "通缉所"
	super._ready()


func build_entries() -> Array:
	var out: Array = []
	for id in State.temp.get("wanted_list", []):
		var info: Dictionary = State.system_flags.get("wanted_%d" % int(id), {})
		var struck := bool(info.get("struck", false))
		var awarded := bool(State.system_flags.get("wanted_award_%d" % int(id), false))
		var state_text := "未击破"
		if struck:
			state_text = "已击破" if awarded else "可领取赏金"
		out.append({"label": "通缉犯 #%d" % int(id), "sub": state_text, "wanted_id": int(id)})
	return out


func info_text() -> String:
	return "赏金 %dG" % REWARD


func on_confirm(index: int) -> void:
	var wanted_id := int(entries[index].get("wanted_id", 0))
	if wanted_id <= 0:
		return
	var info: Dictionary = State.system_flags.get("wanted_%d" % wanted_id, {})
	if not bool(info.get("struck", false)):
		show_notice("还没有击破这个通缉犯")
		return
	if bool(State.system_flags.get("wanted_award_%d" % wanted_id, false)):
		show_notice("赏金已经领取过了")
		return
	State.party.gain_gold(REWARD)
	State.system_flags["wanted_award_%d" % wanted_id] = true
	rebuild()
	show_notice("领取了 %dG 赏金" % REWARD)
