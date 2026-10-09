extends TrackElement

const DEFAULT_TEXTURE := preload("res://assets/track/kerb.png")

@onready var _outer: Line2D = $OuterKerb
@onready var _inner: Line2D = $InnerKerb


func _ready() -> void:
	z_index = -22
	_apply_surface()


func _apply_surface() -> void:
	if _outer == null or _inner == null:
		return
	var tex := surface_texture if surface_texture != null else DEFAULT_TEXTURE
	for line in [_outer, _inner]:
		line.texture = tex
		line.texture_mode = Line2D.LINE_TEXTURE_TILE
		line.width = 8.0
		line.closed = true
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		apply_modulate(line, Track.KERB)
	_outer.points = Track.ellipse_points(Track.OUTER)
	_inner.points = Track.ellipse_points(Track.INNER)
