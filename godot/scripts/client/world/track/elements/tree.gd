extends TrackElement

const DEFAULT_TEXTURE := preload("res://assets/track/tree.png")

@export var scale_factor := 1.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	var tex := surface_texture if surface_texture != null else DEFAULT_TEXTURE
	_sprite.texture = tex
	var size := TrackElement.texture_size(tex)
	_sprite.scale = Vector2.ONE * scale_factor
	_sprite.offset = Vector2(0.0, -size.y * 0.5 * scale_factor)
	apply_modulate(_sprite, Track.TREE_CROWN)
