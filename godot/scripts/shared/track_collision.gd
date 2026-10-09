## Collisions arcade — **serveur uniquement**, après chaque `CarPhysics.step`.
##
## Les obstacles viennent des scènes client (`track.tscn` + marqueurs Collision).
## Le client affiche ; le serveur instancie la piste une fois pour les lire.
class_name TrackCollision
extends RefCounted

## Fallback si aucun `CarSpecs` pour ce peer (aligné `default_car.tres`).
const CAR_RADIUS := 13.0
const CAR_CAR_PASSES := 2
const TRACK_SCENE := preload("res://scenes/client/world/track/track.tscn")


static func load_obstacles_from_track() -> Array[TrackObstacle]:
	var root: Node = TRACK_SCENE.instantiate()
	var list: Array[TrackObstacle] = []
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		push_error("[6TT] TrackCollision : SceneTree indisponible")
		root.free()
		return list
	tree.root.add_child(root)
	_collect_markers(root, list)
	tree.root.remove_child(root)
	root.free()
	return list


static func _collect_markers(node: Node, out: Array[TrackObstacle]) -> void:
	if node is TrackCollisionMarker:
		out.append((node as TrackCollisionMarker).to_obstacle())
	for child in node.get_children():
		_collect_markers(child, out)


static func resolve_tick(
	cars: Dictionary, obstacles: Array[TrackObstacle], specs_by_peer: Dictionary = {}
) -> void:
	if cars.is_empty():
		return
	for _pass in CAR_CAR_PASSES:
		_resolve_car_car(cars, specs_by_peer)
	for peer_id in cars:
		var car: CarState = cars[peer_id]
		var car_radius := _car_radius(car, specs_by_peer)
		for obs in obstacles:
			match obs.kind:
				TrackObstacle.Kind.CIRCLE:
					_push_circle(car, obs.position, obs.radius + car_radius)
				TrackObstacle.Kind.SEGMENT:
					_push_segment(car, obs, car_radius)
				_:
					assert(false, "TrackObstacle kind inattendu : %d" % int(obs.kind))
		CarPhysics.enforce_track_bounds(car)


static func _car_radius(car: CarState, specs_by_peer: Dictionary) -> float:
	if specs_by_peer.has(car.peer_id):
		var specs: CarSpecs = specs_by_peer[car.peer_id]
		return specs.collision_radius()
	return CAR_RADIUS


static func _resolve_car_car(cars: Dictionary, specs_by_peer: Dictionary) -> void:
	var ids: Array = cars.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a := cars[ids[i]] as CarState
			var b := cars[ids[j]] as CarState
			_push_cars_apart(
				a,
				b,
				_car_radius(a, specs_by_peer),
				_car_radius(b, specs_by_peer),
			)


static func _push_cars_apart(a: CarState, b: CarState, radius_a: float, radius_b: float) -> void:
	var delta := b.pos - a.pos
	var min_dist := radius_a + radius_b
	var dist_sq := delta.length_squared()
	if dist_sq >= min_dist * min_dist or dist_sq < 0.001:
		return
	var dist := sqrt(dist_sq)
	var normal := delta / dist
	var overlap := min_dist - dist
	a.pos -= normal * (overlap * 0.5)
	b.pos += normal * (overlap * 0.5)
	_dampen_car(a)
	_dampen_car(b)


static func _push_circle(car: CarState, center: Vector2, combined_radius: float) -> void:
	var delta := car.pos - center
	var dist_sq := delta.length_squared()
	if dist_sq >= combined_radius * combined_radius or dist_sq < 0.001:
		return
	var dist := sqrt(dist_sq)
	var normal := delta / dist
	car.pos = center + normal * combined_radius
	_dampen_car(car)


static func _push_segment(car: CarState, obs: TrackObstacle, car_radius: float) -> void:
	var half := obs.segment_length * 0.5
	var forward := Vector2(cos(obs.rotation), sin(obs.rotation))
	var start := obs.position - forward * half
	var end := obs.position + forward * half
	var closest := _closest_on_segment(car.pos, start, end)
	var delta := car.pos - closest
	var limit := car_radius + obs.segment_thickness * 0.5
	var dist_sq := delta.length_squared()
	if dist_sq >= limit * limit or dist_sq < 0.001:
		return
	var dist := sqrt(dist_sq)
	var normal := delta / dist
	car.pos = closest + normal * limit
	_dampen_car(car)


static func _closest_on_segment(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab := b - a
	var denom := ab.length_squared()
	if denom < 0.001:
		return a
	var t := clampf((p - a).dot(ab) / denom, 0.0, 1.0)
	return a + ab * t


static func _dampen_car(car: CarState) -> void:
	car.speed *= 0.75
