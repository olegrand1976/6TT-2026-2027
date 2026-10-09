extends TrackElement

const DEFAULT_TEXTURE := preload("res://assets/track/dirt.png")

@onready var _poly: Polygon2D = $Polygon2D


func _ready() -> void:
	z_index = -24
	var tex := surface_texture if surface_texture != null else DEFAULT_TEXTURE
	_poly.texture = tex
	_poly.polygon = Track.ellipse_points(Track.INNER)
	apply_modulate(_poly, Track.DIRT)
