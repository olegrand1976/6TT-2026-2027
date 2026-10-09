extends TrackElement

@export var trunk_height := 18.0
@export var trunk_width := 6.0
@export var crown_radius := 22.0


func _draw() -> void:
	draw_rect(
		Rect2(Vector2(-trunk_width * 0.5, -trunk_height), Vector2(trunk_width, trunk_height)),
		resolved_color(Track.TREE_TRUNK),
	)
	draw_circle(Vector2(0.0, -trunk_height), crown_radius, resolved_color(Track.TREE_CROWN))
