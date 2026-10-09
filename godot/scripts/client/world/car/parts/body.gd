extends CarPart

const DEFAULT_TEXTURE := preload("res://assets/car/body.png")
const TEX_SIZE := Vector2(52.0, 28.0)

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_sprite.texture = DEFAULT_TEXTURE


func update_visuals() -> void:
	var view := _car_view()
	if view == null:
		return
	var specs: CarSpecs = view.specs
	_sprite.modulate = view.paint_color
	_sprite.scale = Vector2(specs.body_length / TEX_SIZE.x, specs.body_width / TEX_SIZE.y)
