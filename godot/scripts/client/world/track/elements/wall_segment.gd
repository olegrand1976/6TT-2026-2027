extends TrackElement

@export var length := 80.0
@export var thickness := 6.0


func _draw() -> void:
	var half := length * 0.5
	draw_rect(
		Rect2(Vector2(-half, -thickness * 0.5), Vector2(length, thickness)),
		resolved_color(Track.WALL),
	)
