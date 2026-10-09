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
