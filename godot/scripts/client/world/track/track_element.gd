## Base des éléments de piste : couleur surchargeable dans l'éditeur.
class_name TrackElement
extends Node2D

@export var surface_color: Color = Color.WHITE
@export var use_track_default := true


func resolved_color(default_color: Color) -> Color:
	if use_track_default:
		return default_color
	return surface_color
