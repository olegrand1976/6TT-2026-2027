extends TrackElement


func _ready() -> void:
	z_index = -30


func _draw() -> void:
	var span := Track.OUTER * 2.4
	draw_rect(Rect2(-span, span * 2.0), resolved_color(Track.GRASS))
