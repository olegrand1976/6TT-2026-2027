## Couche réseau partagée (client + serveur) — cœur multijoueur du projet.
##
## Emplacement obligatoire : `/root/Main/Net` des deux côtés (sinon RPC silencieux).
##
## Modèle **autorité serveur** :
##   client → `submit_input` (direction + gaz)
##   serveur → `CarPhysics` + collisions → `snapshot` (toutes les voitures)
##
## Voir aussi : docs/CODE-GODOT.md (boucle 30 Hz).
extends Node

## Simulation réseau à pas fixe (indépendant du FPS d'affichage).
const TICK_RATE := 30.0
const STEP := 1.0 / TICK_RATE
const DEFAULT_CAR_SPECS: CarSpecs = preload("res://resources/cars/default_car.tres")

## Emis sur le client a chaque instantane recu du serveur.
signal snapshot_received

var is_server := false

## Serveur : peer_id -> CarState (source de verite).
var cars: Dictionary = {}
## Serveur : peer_id -> Vector2 (derniere commande recue).
var _inputs: Dictionary = {}
## Serveur : ordre d'arrivee, pour attribuer les places sur la grille.
var _grid_index: Dictionary = {}
## Serveur : peer_id -> profil gameplay (même `.tres` que le client par défaut).
var _specs_by_peer: Dictionary = {}

## Client : dernier instantane recu, peer_id -> CarState.
var remote_cars: Dictionary = {}
## Client : commande locale, mise a jour par le client a chaque image.
var local_input := Vector2.ZERO

var _accumulator := 0.0
var _tick := 0
var _obstacles: Array[TrackObstacle] = []
var _obstacles_loaded := false


func _process(delta: float) -> void:
	# Accumulateur classique : plusieurs ticks si le rendu accroche, zéro si rapide.
	_accumulator += delta
	while _accumulator >= STEP:
		_accumulator -= STEP
		if is_server:
			_server_tick()
		else:
			_client_tick()


# --- Serveur -----------------------------------------------------------------

func add_car(peer_id: int) -> void:
	var car := CarState.new()
	car.peer_id = peer_id
	car.reset(_grid_index.get(peer_id, cars.size()))
	cars[peer_id] = car
	_inputs[peer_id] = Vector2.ZERO
	_specs_by_peer[peer_id] = DEFAULT_CAR_SPECS


func remove_car(peer_id: int) -> void:
	cars.erase(peer_id)
	_inputs.erase(peer_id)
	_grid_index.erase(peer_id)
	_specs_by_peer.erase(peer_id)


func car_specs_for(peer_id: int) -> CarSpecs:
	return _specs_by_peer.get(peer_id, DEFAULT_CAR_SPECS) as CarSpecs


func reserve_grid_slot(peer_id: int) -> void:
	_grid_index[peer_id] = _grid_index.size()


func ensure_obstacles_loaded() -> void:
	# Instancie track.tscn une fois dans l'arbre pour lire les TrackCollisionMarker.
	if _obstacles_loaded or not is_server:
		return
	_obstacles = TrackCollision.load_obstacles_from_track()
	_obstacles_loaded = true
	print("[6TT] obstacles piste : %d marqueur(s)" % _obstacles.size())


func _server_tick() -> void:
	_tick += 1
	ensure_obstacles_loaded()
	for peer_id in cars:
		var specs := car_specs_for(peer_id)
		CarPhysics.step(cars[peer_id], _inputs.get(peer_id, Vector2.ZERO), STEP, specs)
	TrackCollision.resolve_tick(cars, _obstacles, _specs_by_peer)

	if cars.is_empty():
		return
	var payload: Array = []
	for peer_id in cars:
		payload.append(cars[peer_id].to_wire())
	snapshot.rpc(payload)


# --- Client ------------------------------------------------------------------

func _client_tick() -> void:
	if multiplayer.has_multiplayer_peer() \
			and multiplayer.multiplayer_peer.get_connection_status() \
			== MultiplayerPeer.CONNECTION_CONNECTED:
		submit_input.rpc_id(1, local_input.x, local_input.y)


# --- RPC ---------------------------------------------------------------------

## Appele par un client, execute sur le serveur.
@rpc("any_peer", "call_remote", "unreliable_ordered")
func submit_input(steer: float, throttle: float) -> void:
	if not is_server:
		return
	var sender := multiplayer.get_remote_sender_id()
	if cars.has(sender):
		_inputs[sender] = Vector2(steer, throttle)


## Appele par le serveur, execute sur tous les clients.
@rpc("authority", "call_remote", "unreliable_ordered")
func snapshot(payload: Array) -> void:
	var seen: Dictionary = {}
	for row in payload:
		var car := CarState.from_wire(row)
		seen[car.peer_id] = true
		remote_cars[car.peer_id] = car
	for peer_id in remote_cars.keys():
		if not seen.has(peer_id):
			remote_cars.erase(peer_id)
	snapshot_received.emit()
