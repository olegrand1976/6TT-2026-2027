## Etat d'une voiture.
##
## Cote serveur c'est la source de verite ; cote client, la derniere valeur
## recue du serveur (plus une position lissee pour le rendu).
class_name CarState
extends RefCounted

var peer_id: int = 0
var pos := Vector2.ZERO
var heading: float = 0.0
var speed: float = 0.0
var lap: int = 0

## Angle polaire cumule autour du centre du circuit : sert a compter les tours
## sans dependre du sens de rotation ni d'une ligne d'arrivee.
var _sweep: float = 0.0
var _last_polar: float = 0.0


func reset(index: int) -> void:
	pos = Track.spawn_point(index)
	heading = Track.spawn_heading()
	speed = 0.0
	lap = 0
	_sweep = 0.0
	_last_polar = atan2(pos.y, pos.x)


## Met a jour le compteur de tours a partir de la position courante.
func update_lap() -> void:
	var polar := atan2(pos.y, pos.x)
	_sweep += wrapf(polar - _last_polar, -PI, PI)
	_last_polar = polar
	while _sweep >= TAU:
		_sweep -= TAU
		lap += 1
	while _sweep <= -TAU:
		_sweep += TAU
		lap -= 1


## Serialisation compacte pour le reseau : uniquement ce que le client affiche.
func to_wire() -> Array:
	return [peer_id, pos.x, pos.y, heading, speed, lap]


static func from_wire(row: Array) -> CarState:
	var car := CarState.new()
	car.peer_id = int(row[0])
	car.pos = Vector2(row[1], row[2])
	car.heading = row[3]
	car.speed = row[4]
	car.lap = int(row[5])
	return car


## Couleur deterministe deduite de l'identifiant reseau : pas besoin de la
## transmettre, serveur et client trouvent la meme.
static func color_for(peer_id: int) -> Color:
	return Color.from_hsv(fmod(float(peer_id) * 0.6180339887, 1.0), 0.65, 1.0)
