## Rendu du circuit. Dessine une fois : la geometrie ne bouge jamais.
extends Node2D


func _ready() -> void:
	z_index = -10


func _draw() -> void:
	# Herbe : large rectangle derriere tout le reste.
	var span := Track.OUTER * 2.4
	draw_rect(Rect2(-span, span * 2.0), Track.GRASS)

	# Bitume = ellipse exterieure moins ellipse interieure.
	draw_colored_polygon(Track.ellipse_points(Track.OUTER), Track.ASPHALT)
	draw_colored_polygon(Track.ellipse_points(Track.INNER), Track.GRASS)

	# Bordures.
	draw_polyline(_closed(Track.ellipse_points(Track.OUTER)), Track.KERB, 3.0, true)
	draw_polyline(_closed(Track.ellipse_points(Track.INNER)), Track.KERB, 3.0, true)

	# Ligne de depart, sur la ligne droite de droite.
	draw_line(
		Vector2(Track.INNER.x, 0.0), Vector2(Track.OUTER.x, 0.0), Color.WHITE, 4.0
	)


static func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var closed := PackedVector2Array(points)
	if points.size() > 0:
		closed.push_back(points[0])
	return closed
