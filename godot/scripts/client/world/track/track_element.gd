## Base des éléments de piste : texture + teinte surchargeables dans l'éditeur.
class_name TrackElement
extends Node2D

@export var surface_texture: Texture2D
@export var surface_color: Color = Color.WHITE
@export var use_track_default := true


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


## Texture répétée sur une ellipse centrée à l'origine (alignée sur `Track.OUTER` / `INNER`).
static func bind_ellipse_polygon(poly: Polygon2D, tex: Texture2D, radii: Vector2) -> void:
	poly.polygon = Track.ellipse_points(radii)
	if tex == null:
		poly.texture = null
		return
	poly.texture = tex
	poly.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var tile := texture_size(tex)
	if tile.x <= 0.0 or tile.y <= 0.0:
		return
	poly.texture_scale = Vector2(radii.x * 2.0 / tile.x, radii.y * 2.0 / tile.y)
	poly.texture_offset = Vector2.ZERO
