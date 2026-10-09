extends TrackElement

const DEFAULT_TEXTURE := preload("res://assets/track/start_line.png")

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	z_index = -21
	var tex := surface_texture if surface_texture != null else DEFAULT_TEXTURE
	_sprite.texture = tex
	var width := Track.OUTER.x - Track.INNER.x
	var size := TrackElement.texture_size(tex)
	_sprite.scale = Vector2(width / size.x, 1.0)
	_sprite.position = Vector2(Track.INNER.x + width * 0.5, 0.0)
	apply_modulate(_sprite, Color.WHITE)
