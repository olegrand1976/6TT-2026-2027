class_name CarPhysics
extends RefCounted

const MAX_SPEED := 430.0
const MAX_REVERSE := 150.0
const ACCEL := 520.0
const BRAKE := 780.0
const DRAG := 0.9
const TURN_RATE := 2.9
const GRIP_SPEED := 130.0
const OFFTRACK_DRAG := 3.4


static func step(car: CarState, input: Vector2, dt: float) -> void:
	var steer := clampf(input.x, -1.0, 1.0)
	var throttle := clampf(input.y, -1.0, 1.0)
	if throttle > 0.0:
		car.speed += ACCEL * throttle * dt
	elif throttle < 0.0:
		car.speed += BRAKE * throttle * dt
	car.speed -= car.speed * DRAG * dt
	if not Track.is_on_asphalt(car.pos):
		car.speed -= car.speed * OFFTRACK_DRAG * dt
	car.speed = clampf(car.speed, -MAX_REVERSE, MAX_SPEED)
	var grip := clampf(absf(car.speed) / GRIP_SPEED, 0.0, 1.0)
	car.heading = wrapf(
		car.heading + steer * TURN_RATE * grip * signf(car.speed) * dt, -PI, PI
	)
	car.pos += Vector2(cos(car.heading), sin(car.heading)) * car.speed * dt
	_keep_inside(car)
	car.update_lap()


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
