## Caméra 2D qui suit une position monde (voiture locale).
##
## La piste est centrée en `(0, 0)` ; la grille de départ est à droite (~460 px).
## `track_center_influence` rapproche légèrement le cadre du centre de l'ovale
## sans figer la caméra sur la voiture.
class_name Rac6ttFollowCamera
extends Camera2D

@export var default_zoom := Vector2(0.85, 0.85)
@export_range(0.0, 1.0, 0.01) var track_center_influence := 0.15


func _ready() -> void:
	zoom = default_zoom
	position_smoothing_enabled = true
	make_current()


func follow_world_position(world_pos: Vector2) -> void:
	var target := world_pos.lerp(Vector2.ZERO, track_center_influence)
	position = target


func frame_track_center() -> void:
	position = Vector2.ZERO
