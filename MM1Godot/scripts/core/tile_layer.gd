class_name TileLayer
extends Node2D
## Draws RMXP map layers using autotile textures + tileset main texture.
## Tile id ranges:
##   0-383  → autotiles (7 groups × 48 variants each)
##   384+   → tileset main image (index = tid - 384)
##
## RMXP Autotile 正确渲染方式（非直接切 32px tile）：
##
## Autotile 单文件 384×128px, 4 个动画 frame 水平排列 (每 frame 96px)。
## 每个 frame 内是 4 cols × 6 rows = 24 个 16px blocks 的 sub-part 网格。
##
## 每个 32×32 tile = 4 个 16×16 sub-parts 拼接 (TL, TR, BL, BR)。
## AUTOTILE_PARTS 表定义了 48 个 variant 各自的 4 个 sub-part 索引 (0-23)。
##
## sub-part 在图上的位置:
##   col = idx % 4, row = idx / 4
##   src_x = col * 16 + frame * 96
##   src_y = row * 16
##
## 动画: 每 AUTOTILE_FRAME_INTERVAL (20) 帧切换一次 frame, 4 个 frame 循环。
## 边界 variant 的 sub-part 在 frame 间颜色/纹理有差异 → 波浪效果。

const TILE := 32
const SUB := 16                    # sub-part size
const AUTOTILE_COUNT := 7
const AUTOTILE_SIZE := 48          # variants per autotile group
const AUTOTILE_BASE := 384         # tile id boundary
const AUTOTILE_FRAME_INTERVAL := 20  # RMXP DEFAULT_FRAME_INTERVAL
const AUTOTILE_FRAMES := 4           # 4 animation frames

# openrgss AUTOTILE_PARTS — 48 variants, each [TL, TR, BL, BR] sub-part indices (0-23)
# 注意：Godot 4.7 不允许 Packed*Array 作为 const，用 var 初始化
var AUTOTILE_PARTS := PackedInt32Array([
	18,17,14,13,   2,14,17,18,  13, 3,17,18,   2, 3,17,18,
	13,14,17, 7,   2,14,17, 7,  13, 3,17, 7,   2, 3,17, 7,
	13,14, 6,18,   2,14, 6,18,  13, 3, 6,18,   2, 3, 6,18,
	13,14, 6, 7,   2,14, 6, 7,  13, 3, 6, 7,   2, 3, 6, 7,
	16,17,12,13,  16, 3,12,13,  16,17,12, 7,  12, 3,16, 7,
	10, 9,14,13,  10, 9,14, 7,  10, 9, 6,13,  10, 9, 6, 7,
	18,19,14,15,  18,19, 6,15,   2,19,14,15,   2,19, 6,15,
	18,17,22,21,   2,17,22,21,  18, 3,22,21,   2, 3,21,22,
	16,19,12,15,  10, 9,22,21,   8, 9,12,13,   8, 9,12, 7,
	10,11,14,15,  10,11, 6,15,  18,19,22,23,   2,19,22,23,
	16,17,20,21,  16, 3,20,21,   8,11,12,15,   8, 9,20,21,
	16,19,20,23,  10,11,22,23,   8,11,20,23,   0, 1, 4, 5,
])

var SUB_POSITIONS := PackedVector2Array([
	Vector2(0, 0), Vector2(SUB, 0), Vector2(0, SUB), Vector2(SUB, SUB),
])

var tileset_texture: Texture2D = null
var autotile_textures: Array = []
var map_width: int = 0
var map_height: int = 0
var layers: Array = []
var layer_indices: Array = []
var priorities: Array = []
var priority_min: int = -1

# 动画
var _frame_count: int = 0
var _anim_frame: int = 0

# 缓存：autotile_group × variant × frame → Image 的 32×32 纹理
# 每个 autotile group 独立渲染，因为不同 group 的 autotile 图不同
var _tile_cache: Dictionary = {}


func configure(ts_tex: Texture2D, autos: Array, w: int, h: int,
		all_layers: Array, indices: Array,
		tile_priorities: Array = [], min_priority: int = -1) -> void:
	tileset_texture = ts_tex
	autotile_textures = autos
	map_width = w
	map_height = h
	layers = all_layers
	layer_indices = indices
	priorities = tile_priorities
	priority_min = min_priority
	_tile_cache.clear()
	set_process(true)
	queue_redraw()


func _process(_delta: float) -> void:
	_frame_count += 1
	var new_frame := (_frame_count / AUTOTILE_FRAME_INTERVAL) % AUTOTILE_FRAMES
	if new_frame != _anim_frame:
		_anim_frame = new_frame
		queue_redraw()


func _draw() -> void:
	for z in layer_indices:
		if z < 0 or z >= layers.size():
			continue
		var tiles: Array = layers[z]
		for y in range(map_height):
			for x in range(map_width):
				var idx: int = y * map_width + x
				if idx >= tiles.size():
					continue
				var tid: int = int(tiles[idx])
				if tid <= 0:
					continue
				if priority_min >= 0:
					var prio: int = int(priorities[tid]) if tid < priorities.size() else 0
					if prio < priority_min:
						continue
				var pos := Rect2(x * TILE, y * TILE, TILE, TILE)
				if tid < AUTOTILE_BASE:
					_draw_autotile(tid, pos)
				else:
					_draw_tileset(tid - AUTOTILE_BASE, pos)


func _draw_tileset(image_index: int, dest: Rect2) -> void:
	if tileset_texture == null:
		return
	var size := tileset_texture.get_size()
	var cols := int(size.x / TILE)
	if cols <= 0:
		return
	var sx := (image_index % cols) * TILE
	var sy := int(floor(image_index / cols)) * TILE
	if sy + TILE > size.y:
		return
	draw_texture_rect_region(tileset_texture, dest, Rect2(sx, sy, TILE, TILE))


func _get_autotile_image(group: int, variant: int, frame: int) -> Image:
	"""用 AUTOTILE_PARTS 表拼出 variant+frame 对应的 32×32 Image。
	
	参考 openrgss Tilemap#make_autotile:
	  x = (rects[i] % 4) * 16 + sx
	  y = (rects[i] / 4) * 16 + sy
	动画帧通过 sx 偏移: sx = frame * 4 * 16
	"""
	var tex: Texture2D = null
	if group < autotile_textures.size():
		tex = autotile_textures[group]
	if tex == null:
		for t in autotile_textures:
			if t != null:
				tex = t
				break
	if tex == null:
		return null

	var tex_img: Image = tex.get_image()
	if tex_img == null:
		return null
	var tex_size: Vector2 = tex.get_size()

	# sub-part 在 autotile 图的布局: 4 cols x 6 rows = 24 blocks per frame
	# 4 个 frame 水平排列, 每 frame 宽 96px (6 blocks × 16px)
	var base_idx: int = variant * 4
	var frame_sx: int = frame * 96  # 每 frame 水平偏移 96px

	var img: Image = Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	for i in range(4):
		var idx: int = AUTOTILE_PARTS[base_idx + i]
		# water01.png 的 sub-part 2/3/6/7 (col2-3,row0-1) 是透明留白。
		# openrgss 标准表在 variant 2/4 中引用它们, 直接 blit 会露出黑背景
		# (实测 map001 tid=50/52 出现 16x16 全黑洞)。回退到同帧纯水纹块 idx18。
		if idx == 2 or idx == 3 or idx == 6 or idx == 7:
			idx = 18
		var b_col: int = idx % 4
		var b_row: int = idx / 4
		var src_x: int = b_col * SUB + frame_sx
		var src_y: int = b_row * SUB
		# 边界检查
		if src_x + SUB > int(tex_size.x) or src_y + SUB > int(tex_size.y):
			continue
		var sub_img: Image = tex_img.get_region(Rect2i(src_x, src_y, SUB, SUB))
		var dst := Vector2i(int(SUB_POSITIONS[i].x), int(SUB_POSITIONS[i].y))
		img.blit_rect(sub_img, Rect2i(0, 0, SUB, SUB), dst)

	return img


func _draw_autotile(tid: int, dest: Rect2) -> void:
	var group := tid / AUTOTILE_SIZE     # 0..6
	var variant := tid % AUTOTILE_SIZE
	if group < 0 or group >= AUTOTILE_COUNT:
		return

	# 原版 Tilemap fallback: 若对应 group 的 autotile 图未配置，
	# 回退到第一个非空的 autotile 图
	var tex: Texture2D = null
	if group < autotile_textures.size():
		tex = autotile_textures[group]
	if tex == null:
		for t in autotile_textures:
			if t != null:
				tex = t
				break
	if tex == null:
		return

	# 缓存 key
	var cache_key := "%d_%d_%d" % [group, variant, _anim_frame]

	# 查缓存
	if not _tile_cache.has(cache_key):
		var img := _get_autotile_image(group, variant, _anim_frame)
		if img == null:
			return
		var tex2 := ImageTexture.create_from_image(img)
		_tile_cache[cache_key] = tex2

	var cached: Texture2D = _tile_cache[cache_key]
	if cached != null:
		draw_texture(cached, dest.position)
