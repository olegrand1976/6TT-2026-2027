## Marqueur à placer sur une scène d'élément (arbre, rocher, mur…).
## Le serveur parcourt la piste instanciée et collecte ces formes.
class_name TrackCollisionMarker
extends Node2D

enum Shape { CIRCLE, SEGMENT }

@export var shape: Shape = Shape.CIRCLE
@export var radius: float = 22.0
@export var segment_length: float = 80.0
@export var segment_thickness: float = 12.0


func to_obstacle() -> TrackObstacle:
	var obs := TrackObstacle.new()
	if not is_inside_tree():
		push_error("[6TT] TrackCollisionMarker hors arbre : %s" % name)
		return obs
	var gt := global_transform
	obs.position = gt.origin
	obs.rotation = gt.get_rotation()
	match shape:
		Shape.CIRCLE:
			obs.kind = TrackObstacle.Kind.CIRCLE
			obs.radius = _scaled_radius()
		Shape.SEGMENT:
			obs.kind = TrackObstacle.Kind.SEGMENT
			obs.segment_length = _scaled_segment_length()
			obs.segment_thickness = segment_thickness
	return obs


func _scaled_radius() -> float:
	var factor := _parent_scale_factor()
	return radius * factor


func _scaled_segment_length() -> float:
	var parent := get_parent()
	if parent != null:
		var len_val = parent.get("length")
		if len_val != null:
			return float(len_val)
	return segment_length * _parent_scale_factor()


func _parent_scale_factor() -> float:
	var parent := get_parent()
	if parent != null and parent.get("scale_factor") != null:
		return float(parent.scale_factor)
	return 1.0
