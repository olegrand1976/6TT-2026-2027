extends Node

var _peer := WebSocketMultiplayerPeer.new()
var _net: Node


func _ready() -> void:
	_net = get_parent().get_node("Net")
	_net.is_server = true
	var err := _peer.create_server(Net.PORT)
	if err != OK:
		push_error("Serveur ex09 : port %d indisponible (%d)" % [Net.PORT, err])
		get_tree().quit(1)
		return
	multiplayer.multiplayer_peer = _peer
	_net.set_multiplayer_authority(1)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	print("[ex09] Serveur ws://0.0.0.0:%d" % Net.PORT)


func _on_peer_connected(id: int) -> void:
	_net.register_peer(id)
	print("[ex09] Client connecte : %d" % id)


func _on_peer_disconnected(id: int) -> void:
	_net.unregister_peer(id)
	print("[ex09] Client deconnecte : %d" % id)
