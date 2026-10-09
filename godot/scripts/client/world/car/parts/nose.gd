extends CarPart


func _draw() -> void:
	var view := _car_view()
	if view == null:
		return
	var specs: CarSpecs = view.specs
	var forward := Vector2.RIGHT
	var side := forward.orthogonal()
	var half_l: float = specs.body_length * 0.5
	var half_w: float = specs.body_width * 0.5
	var nose := PackedVector2Array([
		forward * half_l + side * half_w,
		forward * half_l - side * half_w,
		forward * (specs.body_length * 0.2) - side * half_w,
		forward * (specs.body_length * 0.2) + side * half_w,
	])
	draw_colored_polygon(nose, view.paint_color.lightened(specs.nose_lighten))
