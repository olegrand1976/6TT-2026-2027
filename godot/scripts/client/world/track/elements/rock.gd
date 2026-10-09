extends TrackElement

const DEFAULT_TEXTURE := preload("res://assets/track/rock.png")

@export var scale_factor := 1.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	var tex := surface_texture if surface_texture != null else DEFAULT_TEXTURE
	_sprite.centered = true
	_sprite.texture = tex
	_sprite.scale = Vector2.ONE * scale_factor
	apply_modulate(_sprite, Track.ROCK)
