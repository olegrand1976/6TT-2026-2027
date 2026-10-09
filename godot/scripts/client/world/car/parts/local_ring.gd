extends CarPart


func _draw() -> void:
	var view := _car_view()
	if view == null or not view.is_local_player:
		return
	var specs := view.specs
	draw_arc(
		Vector2.ZERO,
		specs.body_length * specs.local_ring_radius_factor,
		0.0,
		TAU,
		32,
		Color.WHITE,
		specs.local_ring_width,
		true,
	)
