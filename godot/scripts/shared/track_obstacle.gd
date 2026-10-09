## Obstacle statique du circuit (source de vérité serveur).
class_name TrackObstacle
extends Resource

enum Kind { CIRCLE, SEGMENT }

@export var kind: Kind = Kind.CIRCLE
@export var position: Vector2 = Vector2.ZERO
@export var radius: float = 20.0
@export var segment_length: float = 80.0
@export var segment_thickness: float = 12.0
@export var rotation: float = 0.0
