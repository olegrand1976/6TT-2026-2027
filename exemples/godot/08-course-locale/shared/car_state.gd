class_name CarState
extends RefCounted

var pos := Vector2.ZERO
var heading: float = 0.0
var speed: float = 0.0
var lap: int = 0

var _sweep: float = 0.0
var _last_polar: float = 0.0


func reset(index: int) -> void:
	pos = Track.spawn_point(index)
	heading = Track.spawn_heading()
	speed = 0.0
	lap = 0
	_sweep = 0.0
	_last_polar = atan2(pos.y, pos.x)


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
