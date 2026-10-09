extends TrackElement

const DEFAULT_TEXTURE := preload("res://assets/track/tree.png")

@export var scale_factor := 1.0

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	var tex := surface_texture if surface_texture != null else DEFAULT_TEXTURE
	_sprite.texture = tex
	var size := TrackElement.texture_size(tex)
	_sprite.centered = true
	_sprite.scale = Vector2.ONE * scale_factor
	# Pied de l'arbre sur la position du nœud (offset non multiplié par scale).
	_sprite.offset = Vector2(0.0, -size.y * 0.5)
	apply_modulate(_sprite, Track.TREE_CROWN)
