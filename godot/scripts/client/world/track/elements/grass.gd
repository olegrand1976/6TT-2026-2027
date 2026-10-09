extends TrackElement

const DEFAULT_TEXTURE := preload("res://assets/track/grass.png")

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	z_index = -30
	var tex := surface_texture if surface_texture != null else DEFAULT_TEXTURE
	_sprite.texture = tex
	_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var span := maxf(Track.OUTER.x, Track.OUTER.y) * 2.4
	var size := TrackElement.texture_size(tex)
	_sprite.scale = Vector2(span * 2.0 / size.x, span * 2.0 / size.y)
	apply_modulate(_sprite, Track.GRASS)
