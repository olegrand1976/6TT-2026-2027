extends Node2D

var _peer: WebSocketMultiplayerPeer
var _net: Node
var _local := Vector2.ZERO
var _retry := 0.0
var _status := "connexion..."
var _signals_bound := false


func _ready() -> void:
	_net = get_parent().get_node("Net")
	_bind_multiplayer_signals()
	_try_connect()


func _bind_multiplayer_signals() -> void:
	if _signals_bound:
		return
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	_signals_bound = true


func _on_connected_to_server() -> void:
	_status = "connecte id=%d" % multiplayer.get_unique_id()


func _on_connection_failed() -> void:
	_status = "echec connexion"
	_close_peer()


func _on_server_disconnected() -> void:
	_status = "serveur deconnecte"
	_close_peer()


func _close_peer() -> void:
	if _peer != null:
		_peer.close()
	_peer = null
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer = null


func _is_connected() -> bool:
	return (
		multiplayer.has_multiplayer_peer()
		and multiplayer.multiplayer_peer.get_connection_status()
		== MultiplayerPeer.CONNECTION_CONNECTED
	)


func _process(delta: float) -> void:
	if not _is_connected():
		_retry -= delta
		if _retry <= 0.0:
			_retry = 2.0
			_try_connect()
		queue_redraw()
		return
	if multiplayer.is_server():
		return
	_local.x += Input.get_axis("ui_left", "ui_right") * 220.0 * delta
	_local.y += Input.get_axis("ui_up", "ui_down") * 220.0 * delta
	_net.submit_position.rpc(_local)
	queue_redraw()


func _draw() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(12, 24), _status, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	var my_id := multiplayer.get_unique_id() if _is_connected() else 0
	for id: int in _net.positions.keys():
		var p: Vector2 = _net.positions[id]
		if id == my_id:
			p = _local
		var col := Color.CORNFLOWER_BLUE if id == my_id else Color.ORANGE_RED
		draw_circle(p, 14.0, col)
	if _is_connected() and not _net.positions.has(my_id):
		draw_circle(_local, 14.0, Color.CORNFLOWER_BLUE)


func _try_connect() -> void:
	if _is_connected():
		return
	_close_peer()
	_peer = WebSocketMultiplayerPeer.new()
	var err := _peer.create_client("ws://127.0.0.1:%d" % Net.PORT)
	if err != OK:
		_status = "echec create_client (%d)" % err
		_peer = null
		return
	multiplayer.multiplayer_peer = _peer
	_status = "connexion ws://127.0.0.1:%d..." % Net.PORT
