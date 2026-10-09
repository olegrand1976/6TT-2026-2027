extends TrackElement

const DEFAULT_TEXTURE := preload("res://assets/track/dirt.png")

@onready var _poly: Polygon2D = $Polygon2D


func _ready() -> void:
	z_index = -24
	_apply_surface()


func _apply_surface() -> void:
	if _poly == null:
		return
	var tex := surface_texture if surface_texture != null else DEFAULT_TEXTURE
	TrackElement.bind_ellipse_polygon(_poly, tex, Track.INNER)
	apply_modulate(_poly, Track.DIRT)
