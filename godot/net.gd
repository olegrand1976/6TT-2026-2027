## Couche reseau, partagee par le serveur et le client.
##
## Ce noeud DOIT exister au meme chemin des deux cotes (/root/Main/Net) : Godot
## route les RPC par chemin de noeud, un ecart ici et les appels sont silencieux.
##
## Modele : le serveur fait autorite. Les clients n'envoient que leurs commandes
## (`submit_input`), le serveur simule et renvoie l'etat complet (`snapshot`).
extends Node

const TICK_RATE := 30.0
const STEP := 1.0 / TICK_RATE

## Emis sur le client a chaque instantane recu du serveur.
signal snapshot_received

var is_server := false

## Serveur : peer_id -> CarState (source de verite).
var cars: Dictionary = {}
## Serveur : peer_id -> Vector2 (derniere commande recue).
var _inputs: Dictionary = {}
## Serveur : ordre d'arrivee, pour attribuer les places sur la grille.
var _grid_index: Dictionary = {}

## Client : dernier instantane recu, peer_id -> CarState.
var remote_cars: Dictionary = {}
## Client : commande locale, mise a jour par le client a chaque image.
var local_input := Vector2.ZERO

var _accumulator := 0.0
var _tick := 0


func _process(delta: float) -> void:
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


func remove_car(peer_id: int) -> void:
	cars.erase(peer_id)
	_inputs.erase(peer_id)
	_grid_index.erase(peer_id)


func reserve_grid_slot(peer_id: int) -> void:
	_grid_index[peer_id] = _grid_index.size()


func _server_tick() -> void:
	_tick += 1
	for peer_id in cars:
		CarPhysics.step(cars[peer_id], _inputs.get(peer_id, Vector2.ZERO), STEP)

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
