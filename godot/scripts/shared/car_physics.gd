## Modele de conduite arcade, deterministe et sans etat externe.
##
## Le serveur fait autorite : c'est lui seul qui appelle `step()`. Le client se
## contente d'afficher ce que le serveur lui renvoie.
class_name CarPhysics
extends RefCounted

const MAX_SPEED := 430.0
const MAX_REVERSE := 150.0
const ACCEL := 520.0
const BRAKE := 780.0
const DRAG := 0.9
const TURN_RATE := 2.9
## En dessous de cette vitesse, la direction ne mord presque plus.
const GRIP_SPEED := 130.0
## Freinage supplementaire applique hors du bitume.
const OFFTRACK_DRAG := 3.4


## Avance une voiture d'un pas de temps fixe.
## `input.x` = direction (-1 gauche, +1 droite), `input.y` = accelerateur
## (+1 avant, -1 frein / marche arriere).
static func step(car: CarState, input: Vector2, dt: float, specs: CarSpecs = null) -> void:
	var accel_rate := ACCEL
	var brake_rate := BRAKE
	var max_speed := MAX_SPEED
	var max_reverse := MAX_REVERSE
	var turn_rate := TURN_RATE
	if specs != null:
		accel_rate = specs.accel
		brake_rate = specs.brake
		max_speed = specs.max_speed
		max_reverse = specs.max_reverse
		turn_rate = specs.turn_rate

	var steer := clampf(input.x, -1.0, 1.0)
	var throttle := clampf(input.y, -1.0, 1.0)

	if throttle > 0.0:
		car.speed += accel_rate * throttle * dt
	elif throttle < 0.0:
		car.speed += brake_rate * throttle * dt

	car.speed -= car.speed * DRAG * dt
	if not Track.is_on_asphalt(car.pos):
		car.speed -= car.speed * OFFTRACK_DRAG * dt

	car.speed = clampf(car.speed, -max_reverse, max_speed)

	# La voiture ne tourne que si elle roule, et s'inverse en marche arriere.
	var grip := clampf(absf(car.speed) / GRIP_SPEED, 0.0, 1.0)
	car.heading = wrapf(
		car.heading + steer * turn_rate * grip * signf(car.speed) * dt, -PI, PI
	)

	car.pos += Vector2(cos(car.heading), sin(car.heading)) * car.speed * dt
	_keep_inside(car)
	car.update_lap()


## Rails : la voiture peut mordre l'herbe, mais pas quitter la zone de jeu.
##
## Un point est ramene sur une ellipse en le divisant par la racine de son
## ratio — la projection exacte le long du rayon partant du centre.
static func _keep_inside(car: CarState) -> void:
	if car.pos.length_squared() < 0.01:
		car.pos = Vector2(Track.INNER.x, 0.0)
		return

	var outer := Track.OUTER * 1.18
	var outer_ratio := Track._ratio(car.pos, outer)
	if outer_ratio > 1.0:
		car.pos /= sqrt(outer_ratio)
		car.speed *= 0.35
		return

	var inner := Track.INNER * 0.82
	var inner_ratio := Track._ratio(car.pos, inner)
	if inner_ratio < 1.0:
		car.pos /= sqrt(inner_ratio)
		car.speed *= 0.35
