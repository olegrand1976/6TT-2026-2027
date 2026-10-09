extends CarPart

const DEFAULT_TEXTURE := preload("res://assets/car/nose.png")
const TEX_SIZE := Vector2(20.0, 28.0)

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_sprite.texture = DEFAULT_TEXTURE


func update_visuals() -> void:
	var view := _car_view()
	if view == null:
		return
	var specs: CarSpecs = view.specs
	var nose_len := specs.body_length * 0.38
	var nose_h := specs.body_width * 0.9
	_sprite.modulate = view.paint_color.lightened(specs.nose_lighten)
	_sprite.scale = Vector2(nose_len / TEX_SIZE.x, nose_h / TEX_SIZE.y)
	_sprite.position = Vector2(specs.body_length * 0.32, 0.0)
