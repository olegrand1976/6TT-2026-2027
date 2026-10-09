## Caméra 2D qui suit une position monde (voiture locale).
##
## La piste est centrée en `(0, 0)` ; la grille de départ est à droite (~460 px).
## `track_center_influence` rapproche légèrement le cadre du centre de l'ovale
## sans figer la caméra sur la voiture (ignoré si `auto_fit_track`).
class_name Rac6ttFollowCamera
extends Camera2D

@export var default_zoom := Vector2(0.85, 0.85)
@export_range(0.0, 1.0, 0.01) var track_center_influence := 0.15
@export var auto_fit_track := true
## Marge autour de l'ellipse `Track.OUTER` (1.1 ≈ 10 % de bord).
@export_range(1.0, 1.6, 0.01) var fit_padding := 1.1


func _ready() -> void:
	position_smoothing_enabled = true
	make_current()
	_bind_viewport_resize()
	if auto_fit_track:
		position = Vector2.ZERO
	call_deferred("_apply_zoom")


func _bind_viewport_resize() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	if not vp.size_changed.is_connected(_apply_zoom):
		vp.size_changed.connect(_apply_zoom)


func _apply_zoom() -> void:
	if auto_fit_track:
		zoom = _zoom_to_fit_track()
	else:
		zoom = default_zoom


## Zoom uniforme pour voir tout l'ovale extérieur dans la fenêtre courante.
func _zoom_to_fit_track() -> Vector2:
	var vp_size := get_viewport().get_visible_rect().size
	if vp_size.x <= 1.0 or vp_size.y <= 1.0:
		return default_zoom
	var half := Track.OUTER * fit_padding
	var z := minf(vp_size.x / (2.0 * half.x), vp_size.y / (2.0 * half.y))
	z = maxf(z, 0.05)
	return Vector2(z, z)


func follow_world_position(world_pos: Vector2) -> void:
	if auto_fit_track:
		position = Vector2.ZERO
		return
	var target := world_pos.lerp(Vector2.ZERO, track_center_influence)
	position = target


func frame_track_center() -> void:
	position = Vector2.ZERO
