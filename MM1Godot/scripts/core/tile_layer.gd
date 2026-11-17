class_name TileLayer
extends Node2D
## Draws one or more RMXP map layers using the imported tileset image.
## This project uses an extended ("large") tileset: tile ids >= 384 address
## tileset image indices (id - 384), matching the original engine's behavior.

const TILE := 32

var texture: Texture2D = null
var map_width: int = 0
var map_height: int = 0
var layers: Array = []       # [[int], ...]
var layer_indices: Array = []
var priorities: Array = []   # tile id -> priority
var priority_min: int = -1   # when >= 0 only draw tiles with priority >= min


func configure(tex: Texture2D, w: int, h: int, all_layers: Array, indices: Array,
		tile_priorities: Array = [], min_priority: int = -1) -> void:
	texture = tex
	map_width = w
	map_height = h
	layers = all_layers
	layer_indices = indices
	priorities = tile_priorities
	priority_min = min_priority
	queue_redraw()


func _draw() -> void:
	if texture == null:
		return
	var size := texture.get_size()
	var cols := int(size.x / TILE)
	if cols <= 0:
		return
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
				var image_index: int = tid if tid < 384 else tid - 384
				var sx: int = (image_index % cols) * TILE
				var sy: int = int(floor(image_index / cols)) * TILE
				if sy + TILE > size.y:
					continue
				draw_texture_rect_region(
					texture,
					Rect2(x * TILE, y * TILE, TILE, TILE),
					Rect2(sx, sy, TILE, TILE)
				)
