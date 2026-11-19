class_name WaterRenderer
extends Node2D
## 专用水渲染器 —— 绕开通用 TileLayer 的 autotile 管线，
## 直接根据 map 中存的 variant 从 water01.png 拼出正确的 32×32 tile。
##
## 设计思路:
##   1. 只负责渲染 slot=1 (Godot tid 48..95) 的 autotile —— 地图里的水
##   2. 用 openrgss 的 AUTOTILE_PARTS 表把 water01.png 的 16px sub-part
##      拼成正确的 32×32 variant tile
##   3. 预渲染 48 variants × 4 frames = 192 张 ImageTexture，避免运行时
##      每帧重新 Image blit
##   4. 动画: 每 20 帧切换 frame（和 RMXP DEFAULT_FRAME_INTERVAL 一致）

const TILE := 32
const SUB := 16
const AUTOTILE_COUNT := 7
const AUTOTILE_SIZE := 48          # variants per autotile group
const AUTOTILE_BASE := 384         # tile id boundary
const AUTOTILE_FRAME_INTERVAL := 20
const AUTOTILE_FRAMES := 4

# openrgss AUTOTILE_PARTS —— 48 variants × 4 sub-parts (TL, TR, BL, BR)
# 每个 sub-part 是 water01.png 中 frame 0 的 0..23 索引
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

# 贴图
var _autotile_texture: Texture2D = null   # water01.png

# 地图尺寸和 tile 数据
var _map_width: int = 0
var _map_height: int = 0
var _water_tiles: Array = []     # [[x, y, variant, shore_mask], ...]  —— 只存水 tile
var _all_layers: Array = []      # 所有 layer 的 tile id（用于水陆边界判断）

# 岸线浪花：水陆边界的白色锯齿边（bit 掩码：1=上 2=右 4=下 8=左）
# 原作 RMXP 水 autotile 在靠陆地一侧有 2-3px 白色浪花。这张自定义
# water01.png 的浪花块(idx0/1/4/5/8)只被少数 variant 引用，边界 variant
# (v16/20/24/28)拼出来是纯水，导致大量水陆边界没有浪花。这里用 atlas
# 的真实浪花纹理生成 4 条岸边纹理，按边界方向叠加，保证所有边界都有浪花。
var _shore_textures: Dictionary = {}   # mask -> ImageTexture (16x16 角 / 32x8 边)
const SHORE_WHITE := Color(0.93, 0.96, 1.0, 1.0)

# 预渲染缓存: variant × frame → ImageTexture
# 注意: 只用一个 autotile group (water)，所以不需要 group 维度
var _tile_cache: Dictionary = {}

# 动画状态
var _frame_count: int = 0
var _anim_frame: int = 0


func configure(water_tex: Texture2D, w: int, h: int, layers: Array) -> void:
	"""配置 WaterRenderer.
	
	Args:
	  water_tex: water01.png 的 Texture2D
	  w, h: 地图宽高
	  layers: 所有 layer 的 tile id 数组
	"""
	_autotile_texture = water_tex
	_map_width = w
	_map_height = h
	_all_layers = layers
	_tile_cache.clear()
	_water_tiles.clear()
	
	# 从 layers 中提取所有水 tile (slot = 1, tid 48..95)
	for z in range(layers.size()):
		var tiles: Array = layers[z]
		for y in range(h):
			for x in range(w):
				var idx: int = y * w + x
				if idx >= tiles.size():
					continue
				var tid: int = int(tiles[idx])
				if 48 <= tid and tid < AUTOTILE_BASE:
					var variant: int = tid % AUTOTILE_SIZE
					_water_tiles.append([x, y, variant, 0])

	# 计算每个水 tile 的水陆边界掩码（挨着陆地的方向）
	for t in _water_tiles:
		t[3] = _shore_mask(t[0], t[1])
	
	# 预渲染所有需要的 variant × frame
	_pre_render()
	_build_shore_textures()
	
	set_process(true)
	queue_redraw()


func _is_water_cell(x: int, y: int) -> bool:
	"""任意 layer 上该格是否为水 autotile (tid 48..95)。"""
	if x < 0 or y < 0 or x >= _map_width or y >= _map_height:
		return false
	var idx: int = y * _map_width + x
	for z in range(_all_layers.size()):
		var tiles: Array = _all_layers[z]
		if idx >= tiles.size():
			continue
		var tid: int = int(tiles[idx])
		if 48 <= tid and tid < AUTOTILE_BASE:
			return true
	return false


func _has_land(x: int, y: int) -> bool:
	"""该格是否存在非水的陆地 tile（tid>0 且不是水 autotile）。"""
	if x < 0 or y < 0 or x >= _map_width or y >= _map_height:
		return false
	var idx: int = y * _map_width + x
	for z in range(_all_layers.size()):
		var tiles: Array = _all_layers[z]
		if idx >= tiles.size():
			continue
		var tid: int = int(tiles[idx])
		if tid > 0 and not (48 <= tid and tid < AUTOTILE_BASE):
			return true
	return false


func _shore_mask(x: int, y: int) -> int:
	"""返回水 tile 的水陆边界掩码：邻侧是陆地则置位。
	1=上 2=右 4=下 8=左。邻格是水不置位；邻格越界不置位（地图外不画浪花）。"""
	var m: int = 0
	if _has_land(x, y - 1) and not _is_water_cell(x, y - 1): m |= 1
	if _has_land(x + 1, y) and not _is_water_cell(x + 1, y): m |= 2
	if _has_land(x, y + 1) and not _is_water_cell(x, y + 1): m |= 4
	if _has_land(x - 1, y) and not _is_water_cell(x - 1, y): m |= 8
	return m


func _pre_render() -> void:
	"""预渲染 water01.png 的 48 variants × 4 frames 到缓存。"""
	if _autotile_texture == null:
		push_error("WaterRenderer: water texture is null!")
		return
	
	var tex_img: Image = _autotile_texture.get_image()
	if tex_img == null:
		push_error("WaterRenderer: water texture has no Image!")
		return
	
	for v in range(AUTOTILE_SIZE):
		for f in range(AUTOTILE_FRAMES):
			var img: Image = _build_variant_image(tex_img, v, f)
			if img != null:
				var tex2: ImageTexture = ImageTexture.create_from_image(img)
				_tile_cache["%d_%d" % [v, f]] = tex2


func _build_variant_image(tex_img: Image, variant: int, frame: int) -> Image:
	"""用 AUTOTILE_PARTS 表拼出 variant+frame 的 32×32 Image.
	
	sub-part 位置 (water01.png 内):
	  col = idx % 4, row = idx / 4
	  src_x = col * 16 + frame * 96   (每 frame 水平 96px 宽)
	  src_y = row * 16
	"""
	var tex_size := tex_img.get_size()
	var base_idx: int = variant * 4
	var frame_sx: int = frame * 96
	
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


func _build_shore_textures() -> void:
	"""生成水陆边界浪花纹理。
	每条边用 atlas 顶部浪花块(idx0/1)的真实白色纹理，缩放成贴边的细浪花。
	为简单稳定，这里程序化生成 32px 长的白色锯齿条（3px 宽），与原作形态一致。"""
	_shore_textures.clear()
	# 4 个方向各一条水平浪花条（宽32,高3）；垂直方向绘制时旋转使用
	for d in range(4):
		var img: Image = Image.create(TILE, 3, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		# 白色锯齿：交替的实线段，形成 2-3px 不规则白边
		for x in range(TILE):
			var a: float = 1.0
			# 锯齿相位：每 4px 一个波峰，模拟浪花碎边
			var ph: int = x % 4
			if ph == 3:
				a = 0.35
			elif ph == 2:
				a = 0.75
			img.set_pixel(x, 0, Color(SHORE_WHITE.r, SHORE_WHITE.g, SHORE_WHITE.b, a))
			img.set_pixel(x, 1, Color(SHORE_WHITE.r, SHORE_WHITE.g, SHORE_WHITE.b, a * 0.92))
			img.set_pixel(x, 2, Color(SHORE_WHITE.r, SHORE_WHITE.g, SHORE_WHITE.b, a * 0.5))
		_shore_textures[d] = ImageTexture.create_from_image(img)


func _draw_shore_edge(px: float, py: float, mask: int) -> void:
	"""在一个水 tile 上叠加岸线浪花。px/py 是 tile 左上角。"""
	if mask == 0 or _shore_textures.is_empty():
		return
	var edge: Texture2D = _shore_textures[0]
	# 上边：贴 tile 顶，水平
	if mask & 1:
		draw_texture(edge, Vector2(px, py))
	# 下边：贴 tile 底，水平
	if mask & 4:
		draw_texture(edge, Vector2(px, py + TILE - 3))
	# 左边：贴 tile 左侧，垂直（旋转 90°）
	if mask & 8:
		draw_set_transform(Vector2(px, py + TILE), -PI / 2.0, Vector2.ONE)
		draw_texture(edge, Vector2(0, 0))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 右边：贴 tile 右侧，垂直（旋转 90°）
	if mask & 2:
		draw_set_transform(Vector2(px + TILE, py), PI / 2.0, Vector2.ONE)
		draw_texture(edge, Vector2(0, 0))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _process(_delta: float) -> void:
	_frame_count += 1
	var new_frame := (_frame_count / AUTOTILE_FRAME_INTERVAL) % AUTOTILE_FRAMES
	if new_frame != _anim_frame:
		_anim_frame = new_frame
		queue_redraw()


func _draw() -> void:
	if _water_tiles.is_empty():
		return
	
	for tile_data in _water_tiles:
		var x: int = tile_data[0]
		var y: int = tile_data[1]
		var variant: int = tile_data[2]
		var shore_mask: int = tile_data[3] if tile_data.size() > 3 else 0
		
		var cache_key := "%d_%d" % [variant, _anim_frame]
		var cached: Texture2D = _tile_cache.get(cache_key, null)
		if cached == null:
			continue
		
		var pos := Vector2(x * TILE, y * TILE)
		draw_texture(cached, pos)
		# 水陆边界：叠加白色浪花边（保证所有挨陆地的水面都有浪花）
		_draw_shore_edge(pos.x, pos.y, shore_mask)
