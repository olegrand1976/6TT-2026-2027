extends CarPart

const DEFAULT_TEXTURE := preload("res://assets/car/local_ring.png")
const TEX_SIZE := 64.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_sprite.texture = DEFAULT_TEXTURE


func update_visuals() -> void:
	var view := _car_view()
	if view == null:
		return
	var specs: CarSpecs = view.specs
	var show := view.is_local_player
	_sprite.visible = show
	if not show:
		return
	var diameter := specs.body_length * specs.local_ring_radius_factor * 2.0
	_sprite.scale = Vector2.ONE * (diameter / TEX_SIZE)
	_sprite.modulate = Color(1, 1, 1, 0.85)
