extends TrackElement


func _ready() -> void:
	z_index = -21


func _draw() -> void:
	draw_line(
		Vector2(Track.INNER.x, 0.0),
		Vector2(Track.OUTER.x, 0.0),
		resolved_color(Color.WHITE),
		4.0,
	)
