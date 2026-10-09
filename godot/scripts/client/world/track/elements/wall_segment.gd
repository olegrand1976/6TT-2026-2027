extends TrackElement

const DEFAULT_TEXTURE := preload("res://assets/track/wall.png")

@export var length := 80.0
@export var thickness := 6.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	var tex := surface_texture if surface_texture != null else DEFAULT_TEXTURE
	_sprite.centered = true
	_sprite.texture = tex
	var size := TrackElement.texture_size(tex)
	_sprite.scale = Vector2(length / size.x, thickness / size.y)
	apply_modulate(_sprite, Track.WALL)
