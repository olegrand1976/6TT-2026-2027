## Serveur dédié headless (conteneur Docker `godot`).
##
## Rôle : ouvrir le WebSocket, connecter/déconnecter les pilotes dans `Net`.
## La simulation 30 Hz est dans `net.gd` (`is_server = true`).
extends Node

var _peer := WebSocketMultiplayerPeer.new()
var _port := 8999
var _net: Node

@onready var _heartbeat = $HeartbeatMonitor


func _ready() -> void:
	_net = get_parent().get_node("Net")
	_net.is_server = true

	var raw_port := OS.get_environment("GAME_PORT")
	if raw_port != "" and raw_port.is_valid_int():
		_port = int(raw_port)

	var err := _peer.create_server(_port, "*")
	if err != OK:
		push_error("[6TT] Ouverture impossible sur le port %d (erreur %d)" % [_port, err])
		get_tree().quit(1)
		return

	multiplayer.multiplayer_peer = _peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	print("[6TT] Serveur Godot headless a l'ecoute sur ws://0.0.0.0:%d" % _port)
	print("[6TT] Backend cible : %s" % OS.get_environment("BACKEND_URL"))

	_heartbeat.configure(_net)


func _on_peer_connected(id: int) -> void:
	_net.reserve_grid_slot(id)
	_net.add_car(id)
	print("[6TT] Pilote connecte : %d (%d en piste)" % [id, _net.cars.size()])


func _on_peer_disconnected(id: int) -> void:
	_net.remove_car(id)
	print("[6TT] Pilote deconnecte : %d (%d en piste)" % [id, _net.cars.size()])
