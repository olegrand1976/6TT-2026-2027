extends TrackElement


func _ready() -> void:
	z_index = -22


func _draw() -> void:
	var color := resolved_color(Track.KERB)
	draw_polyline(_closed(Track.ellipse_points(Track.OUTER)), color, 3.0, true)
	draw_polyline(_closed(Track.ellipse_points(Track.INNER)), color, 3.0, true)


static func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var closed := PackedVector2Array(points)
	if points.size() > 0:
		closed.push_back(points[0])
	return closed
