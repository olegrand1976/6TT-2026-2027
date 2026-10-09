extends TrackElement


func _ready() -> void:
	z_index = -25


func _draw() -> void:
	draw_colored_polygon(Track.ellipse_points(Track.OUTER), resolved_color(Track.ASPHALT))
