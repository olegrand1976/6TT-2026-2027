## Caméra 2D qui suit une position monde (voiture locale).
class_name Rac6ttFollowCamera
extends Camera2D

@export var default_zoom := Vector2(0.85, 0.85)


func _ready() -> void:
	zoom = default_zoom
	make_current()


func follow_world_position(world_pos: Vector2) -> void:
	global_position = world_pos
