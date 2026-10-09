extends TrackElement

@export var radius := 8.0


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, resolved_color(Track.ROCK))
