extends TrackElement


func _ready() -> void:
	z_index = -24


func _draw() -> void:
	draw_colored_polygon(Track.ellipse_points(Track.INNER), resolved_color(Track.DIRT))
