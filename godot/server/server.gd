## Serveur dedie headless.
##
## Ouvre le WebSocket, gere le cycle de vie des pilotes et journalise. La
## simulation elle-meme vit dans Net, partage avec le client.
extends Node

const HEARTBEAT_SECONDS := 15.0

var _peer := WebSocketMultiplayerPeer.new()
var _port := 8999
var _net: Node


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

	var heartbeat := Timer.new()
	heartbeat.wait_time = HEARTBEAT_SECONDS
	heartbeat.timeout.connect(_on_heartbeat)
	add_child(heartbeat)
	heartbeat.start()


func _on_peer_connected(id: int) -> void:
	_net.reserve_grid_slot(id)
	_net.add_car(id)
	print("[6TT] Pilote connecte : %d (%d en piste)" % [id, _net.cars.size()])


func _on_peer_disconnected(id: int) -> void:
	_net.remove_car(id)
	print("[6TT] Pilote deconnecte : %d (%d en piste)" % [id, _net.cars.size()])


func _on_heartbeat() -> void:
	var laps := 0
	for peer_id in _net.cars:
		laps = maxi(laps, _net.cars[peer_id].lap)
	print("[6TT] heartbeat pilotes=%d meilleur_tour=%d" % [_net.cars.size(), laps])
