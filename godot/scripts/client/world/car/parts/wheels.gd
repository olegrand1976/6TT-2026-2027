extends CarPart


func _draw() -> void:
	var view := _car_view()
	if view == null:
		return
	var specs := view.specs
	var r := specs.wheel_radius
	var color := view.paint_color.darkened(0.35)
	for offset in _wheel_offsets(specs):
		draw_circle(offset, r, color)


func _wheel_offsets(specs: CarSpecs) -> Array[Vector2]:
	var f := specs.wheel_offset_forward
	var s := specs.wheel_offset_side
	return [
		Vector2(f, s),
		Vector2(f, -s),
		Vector2(-f, s),
		Vector2(-f, -s),
	]
