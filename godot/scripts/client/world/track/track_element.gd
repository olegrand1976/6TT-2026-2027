## Base des éléments de piste : texture + teinte surchargeables dans l'éditeur.
class_name TrackElement
extends Node2D

@export var surface_texture: Texture2D
@export var surface_color: Color = Color.WHITE
@export var use_track_default := true


func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"surface_texture":
			surface_texture = value as Texture2D
			_on_surface_exports_changed()
			return true
		&"surface_color":
			surface_color = value as Color
			_on_surface_exports_changed()
			return true
		&"use_track_default":
			use_track_default = value as bool
			_on_surface_exports_changed()
			return true
	return false


func _on_surface_exports_changed() -> void:
	queue_redraw()
	if has_method("_apply_surface"):
		call("_apply_surface")


func resolved_color(default_color: Color) -> Color:
	if use_track_default:
		return default_color
	return surface_color


func apply_modulate(target: CanvasItem, _palette_default: Color) -> void:
	if use_track_default:
		# Textures déjà colorées : ne pas teinter avec la palette procédurale.
		target.modulate = Color.WHITE
	else:
		target.modulate = surface_color


static func texture_size(tex: Texture2D) -> Vector2:
	var size: Vector2i = tex.get_size()
	return Vector2(float(size.x), float(size.y))


## UV en coordonnées monde : même phase de tiling que `draw_world_tiled_rect`.
static func world_tile_uvs(points: PackedVector2Array, tile: Vector2) -> PackedVector2Array:
	var uvs := PackedVector2Array()
	for p in points:
		uvs.push_back(Vector2(p.x / tile.x, p.y / tile.y))
	return uvs


## Remplit un rectangle avec une texture carrelée sur la grille monde (origine 0,0).
static func draw_world_tiled_rect(
	canvas: CanvasItem, tex: Texture2D, rect: Rect2, modulate: Color = Color.WHITE
) -> void:
	var tile := texture_size(tex)
	if tile.x <= 0.0 or tile.y <= 0.0:
		return
	var x0 := int(floor(rect.position.x / tile.x))
	var y0 := int(floor(rect.position.y / tile.y))
	var x1 := int(ceil(rect.end.x / tile.x))
	var y1 := int(ceil(rect.end.y / tile.y))
	for ix in range(x0, x1):
		for iy in range(y0, y1):
			var dest := Rect2(float(ix) * tile.x, float(iy) * tile.y, tile.x, tile.y)
			var clip := rect.intersection(dest)
			if clip.size.x <= 0.0 or clip.size.y <= 0.0:
				continue
			var src := Rect2(clip.position - dest.position, clip.size)
			canvas.draw_texture_rect_region(tex, clip, src, modulate)


## Texture répétée sur une ellipse centrée à l'origine (alignée sur `Track.OUTER` / `INNER`).
static func bind_ellipse_polygon(poly: Polygon2D, tex: Texture2D, radii: Vector2) -> void:
	var points := Track.ellipse_points(radii)
	poly.polygon = points
	if tex == null:
		poly.texture = null
		poly.uv = PackedVector2Array()
		return
	poly.texture = tex
	poly.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var tile := texture_size(tex)
	if tile.x <= 0.0 or tile.y <= 0.0:
		return
	poly.texture_scale = Vector2.ONE
	poly.texture_offset = Vector2.ZERO
	poly.uv = world_tile_uvs(points, tile)
