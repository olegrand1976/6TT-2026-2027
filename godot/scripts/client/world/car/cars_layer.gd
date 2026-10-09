extends Node2D

const CAR_VIEW_SCENE: PackedScene = preload("res://scenes/client/world/car/car_view.tscn")

var _views: Dictionary = {}
var _client: Rac6ttClient
var _net: Node


func _ready() -> void:
	_client = get_tree().get_first_node_in_group("rac6tt_client") as Rac6ttClient
	if _client == null:
		push_error(
			"[6TT] CarsLayer : aucun Rac6ttClient dans le groupe rac6tt_client "
			+ "(ouvrir scenes/main.tscn, pas cars_layer seul)."
		)
		return
	_net = _client.get_parent().get_node("Net")


func _process(_delta: float) -> void:
	if _client == null:
		return
	_sync_views()


func _sync_views() -> void:
	var seen: Dictionary = {}
	var local_id := _client.local_peer_id()

	for peer_id in _net.remote_cars:
		seen[peer_id] = true
		var car: CarState = _net.remote_cars[peer_id]
		var view := _ensure_view(peer_id)
		view.sync_transform(_client.smoothed_position(car), car.heading)
		view.update_appearance(car, peer_id == local_id)

	for peer_id in _views.keys():
		if not seen.has(peer_id):
			(_views[peer_id] as Node).queue_free()
			_views.erase(peer_id)


func _ensure_view(peer_id: int) -> Rac6ttCarView:
	if _views.has(peer_id):
		return _views[peer_id] as Rac6ttCarView
	var view := CAR_VIEW_SCENE.instantiate() as Rac6ttCarView
	view.name = "Car_%d" % peer_id
	add_child(view)
	_views[peer_id] = view
	return view
