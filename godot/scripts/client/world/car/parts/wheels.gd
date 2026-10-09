extends CarPart

const DEFAULT_TEXTURE := preload("res://assets/car/wheel.png")
const TEX_SIZE := 16.0

@onready var _fl: Sprite2D = $FrontLeft
@onready var _fr: Sprite2D = $FrontRight
@onready var _rl: Sprite2D = $RearLeft
@onready var _rr: Sprite2D = $RearRight


func _ready() -> void:
	for wheel in [_fl, _fr, _rl, _rr]:
		wheel.texture = DEFAULT_TEXTURE


func update_visuals() -> void:
	var view := _car_view()
	if view == null:
		return
	var specs: CarSpecs = view.specs
	var scale_val := specs.wheel_radius * 2.0 / TEX_SIZE
	var scale := Vector2.ONE * scale_val
	var color: Color = view.paint_color.darkened(0.35)
	var wheels: Array = [
		[_fl, Vector2(specs.wheel_offset_forward, specs.wheel_offset_side)],
		[_fr, Vector2(specs.wheel_offset_forward, -specs.wheel_offset_side)],
		[_rl, Vector2(-specs.wheel_offset_forward, specs.wheel_offset_side)],
		[_rr, Vector2(-specs.wheel_offset_forward, -specs.wheel_offset_side)],
	]
	for entry in wheels:
		var spr: Sprite2D = entry[0]
		spr.position = entry[1]
		spr.scale = scale
		spr.modulate = color
