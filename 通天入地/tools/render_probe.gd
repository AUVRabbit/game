extends Node

var out_dir := ProjectSettings.globalize_path("res://") + "docs/FULL_TEST_2026-11-22/screenshots/"

func _ready() -> void:
	call_deferred("_attach")

func _attach() -> void:
	print("PROBE attach")
	var tree := get_tree()
	if get_parent() != tree.root:
		var p := get_parent()
		if p != null:
			p.remove_child(self)
		tree.root.add_child(self)
	print("PROBE attached root=%s" % str(get_parent() == tree.root))
	call_deferred("_run")

func _run() -> void:
	print("PROBE run start")
	GameManager.enter_main_menu()
	print("PROBE menu called")
	await get_tree().create_timer(1.4, true).timeout
	print("PROBE timer done")
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(out_dir)
	var suffix := "headless" if DisplayServer.get_name() == "headless" else "windowed"
	var path := out_dir + "probe_%s.jpg" % suffix
	img.save_jpg(path, 0.9)
	var pixel := img.get_pixel(40, 40)
	print("PROBE mode=%s size=%dx%d pixel=%s path=%s" % [suffix, img.get_width(), img.get_height(), str(pixel), path])
	get_tree().quit(0)
