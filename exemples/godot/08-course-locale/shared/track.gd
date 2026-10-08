## Piste elliptique (anneau) — version pédagogique Rac6TT.
class_name Track
extends RefCounted

const OUTER := Vector2(560.0, 340.0)
const INNER := Vector2(300.0, 150.0)
const ASPHALT := Color("#2c3038")
const GRASS := Color("#16301f")
const KERB := Color("#c8ccd4")


static func _ratio(p: Vector2, radii: Vector2) -> float:
	return (p.x * p.x) / (radii.x * radii.x) + (p.y * p.y) / (radii.y * radii.y)


static func is_on_asphalt(p: Vector2) -> bool:
	return _ratio(p, OUTER) <= 1.0 and _ratio(p, INNER) >= 1.0


static func spawn_point(index: int) -> Vector2:
	var column := index % 2
	var row := (index // 2) % 5
	return Vector2(460.0 - float(column) * 60.0, -30.0 - float(row) * 45.0)


static func spawn_heading() -> float:
	return PI * 0.5


static func ellipse_points(radii: Vector2, segments: int = 96) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		points.push_back(Vector2(cos(a) * radii.x, sin(a) * radii.y))
	return points
