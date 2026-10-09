## Géométrie du circuit (anneau elliptique) — **sans état**, partagée client/serveur.
##
## Toute la piste est centrée en (0, 0). Le serveur appelle `is_on_asphalt` et
## les rebords ; le client s'en sert pour dessiner ellipses et grille de départ.
##
## Modifier OUTER/INNER ici change gameplay **et** rendu (garder les scènes cohérentes).
class_name Track
extends RefCounted

## Demi-axes de l'ellipse exterieure, en pixels.
const OUTER := Vector2(560.0, 340.0)
## Demi-axes de l'ellipse interieure (le trou de l'anneau).
const INNER := Vector2(300.0, 150.0)

const ASPHALT := Color("#2c3038")
const GRASS := Color("#16301f")
const DIRT := Color("#3d2817")
const KERB := Color("#c8ccd4")
const WALL := Color("#5a6270")
const TREE_TRUNK := Color("#4a3520")
const TREE_CROWN := Color("#1e4d2b")
const ROCK := Color("#6b7280")


## Ratio de position sur une ellipse : <= 1 signifie a l'interieur.
static func _ratio(p: Vector2, radii: Vector2) -> float:
	return (p.x * p.x) / (radii.x * radii.x) + (p.y * p.y) / (radii.y * radii.y)


## Vrai si le point est sur le bitume (dans l'anneau).
static func is_on_asphalt(p: Vector2) -> bool:
	return _ratio(p, OUTER) <= 1.0 and _ratio(p, INNER) >= 1.0


## Position de depart d'un pilote, sur la ligne droite de droite.
## Les voitures sont rangees en deux colonnes, comme sur une grille de depart.
static func spawn_point(index: int) -> Vector2:
	var column := index % 2
	var row := int(index / 2) % 5
	return Vector2(460.0 - float(column) * 60.0, -30.0 - float(row) * 45.0)


## Cap initial : les voitures partent vers le bas de l'ecran (sens horaire).
static func spawn_heading() -> float:
	return PI * 0.5


## Points d'une ellipse, pour le rendu et rien d'autre.
static func ellipse_points(radii: Vector2, segments: int = 96, start_angle: float = 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments:
		var a := start_angle + TAU * float(i) / float(segments)
		points.push_back(Vector2(cos(a) * radii.x, sin(a) * radii.y))
	return points
