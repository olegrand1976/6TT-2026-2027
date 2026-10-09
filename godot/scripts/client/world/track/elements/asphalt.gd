extends TrackElement

const DEFAULT_TEXTURE := preload("res://assets/track/asphalt.png")

@onready var _poly: Polygon2D = $Polygon2D


func _ready() -> void:
	z_index = -25
	var tex := surface_texture if surface_texture != null else DEFAULT_TEXTURE
	TrackElement.bind_ellipse_polygon(_poly, tex, Track.OUTER)
	apply_modulate(_poly, Track.ASPHALT)
