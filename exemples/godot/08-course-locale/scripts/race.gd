extends Node2D

var _car := CarState.new()
var _hud: Label
var _camera: Camera2D


func _ready() -> void:
	_car.reset(0)
	_camera = Camera2D.new()
	_camera.zoom = Vector2(0.85, 0.85)
	add_child(_camera)
	_camera.make_current()
	_hud = Label.new()
	_hud.position = Vector2(16, 12)
	add_child(_hud)


func _process(delta: float) -> void:
	var input := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_down", "ui_up")
	)
	CarPhysics.step(_car, input, delta)
	_camera.global_position = _car.pos
	_hud.text = "Tour %d · vitesse %.0f\nFlèches = direction / gaz" % [_car.lap, _car.speed]
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, Track.OUTER.length(), Track.GRASS)
	var outer := Track.ellipse_points(Track.OUTER)
	var inner := Track.ellipse_points(Track.INNER)
	draw_colored_polygon(outer, Track.ASPHALT)
	draw_colored_polygon(inner, Track.GRASS)
	var nose := Vector2(cos(_car.heading), sin(_car.heading)) * 22.0
	var wing := Vector2(-sin(_car.heading), cos(_car.heading)) * 10.0
	var p := _car.pos
	draw_colored_polygon(
		PackedVector2Array([p + nose, p - nose * 0.4 + wing, p - nose * 0.4 - wing]),
		Color("#58a6ff")
	)
