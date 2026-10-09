## Client de jeu : connexion WebSocket, entrees joueur, orchestration des scènes.
##
## Le rendu est entierement decoupe en sous-scènes (`world/`, `camera/`, `ui/`).
class_name Rac6ttClient
extends Node2D

const DEFAULT_PORT := 6604
const RETRY_SECONDS := 3.0

@onready var _net: Node = get_parent().get_node("Net")
@onready var _follow_camera = $FollowCamera
@onready var _hud: Rac6ttHud = $HUD

var _peer: WebSocketMultiplayerPeer
var _status := "demarrage..."
var _url := ""
var _connected := false
var _retry_in := 0.0

var _smoothed: Dictionary = {}


func _enter_tree() -> void:
	add_to_group("rac6tt_client")


func _ready() -> void:
	_net.snapshot_received.connect(_on_first_snapshot, CONNECT_ONE_SHOT)

	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	_try_connect()


func _on_first_snapshot() -> void:
	print("[6TT] premier instantane recu — %d voiture(s) en piste"
			% _net.remote_cars.size())


func _try_connect() -> void:
	_url = _server_url()
	_peer = WebSocketMultiplayerPeer.new()

	var err := _peer.create_client(_url)
	if err != OK:
		_status = "URL invalide : %s (erreur %d)" % [_url, err]
		push_error("[6TT] " + _status)
		_retry_in = RETRY_SECONDS
		return

	multiplayer.multiplayer_peer = _peer
	_status = "connexion a %s..." % _url


func _on_connected() -> void:
	_connected = true
	_status = "en piste"
	print("[6TT] connecte au serveur %s" % _url)


func _on_connection_failed() -> void:
	_drop("serveur injoignable")


func _on_server_disconnected() -> void:
	_drop("serveur arrete")


func _drop(reason: String) -> void:
	_connected = false
	_status = reason
	_retry_in = RETRY_SECONDS
	_net.remote_cars.clear()
	_smoothed.clear()


func _update_connection(delta: float) -> void:
	if _connected:
		return

	var status := MultiplayerPeer.CONNECTION_DISCONNECTED
	if multiplayer.has_multiplayer_peer():
		status = multiplayer.multiplayer_peer.get_connection_status()
	if status != MultiplayerPeer.CONNECTION_DISCONNECTED:
		return

	_retry_in -= delta
	if _retry_in <= 0.0:
		_try_connect()


func _server_url() -> String:
	if not OS.has_feature("web"):
		var override := OS.get_environment("GAME_WS_URL")
		if override != "":
			return override
		return "ws://127.0.0.1:%d" % DEFAULT_PORT

	var forced := str(JavaScriptBridge.eval(
		"new URLSearchParams(window.location.search).get('port') || ''", true
	))
	var scheme := "wss" if str(JavaScriptBridge.eval(
		"window.location.protocol", true
	)) == "https:" else "ws"

	if forced.is_valid_int():
		var host := str(JavaScriptBridge.eval("window.location.hostname", true))
		return "%s://%s:%d" % [scheme, host, int(forced)]

	var host_port := str(JavaScriptBridge.eval("window.location.host", true))
	return "%s://%s/ws" % [scheme, host_port]


func _process(delta: float) -> void:
	_update_connection(delta)

	_net.local_input = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_down", "ui_up"),
	)

	_update_smoothing(delta)

	var me: CarState = _net.remote_cars.get(local_peer_id())
	if me != null:
		_follow_camera.follow_world_position(_smoothed.get(me.peer_id, me.pos))

	_hud.set_status_text(_hud_text(me))


func _update_smoothing(delta: float) -> void:
	var weight := clampf(delta * 18.0, 0.0, 1.0)
	for peer_id in _net.remote_cars:
		var target: Vector2 = _net.remote_cars[peer_id].pos
		if _smoothed.has(peer_id):
			_smoothed[peer_id] = (_smoothed[peer_id] as Vector2).lerp(target, weight)
		else:
			_smoothed[peer_id] = target
	for peer_id in _smoothed.keys():
		if not _net.remote_cars.has(peer_id):
			_smoothed.erase(peer_id)


func smoothed_position(car: CarState) -> Vector2:
	return _smoothed.get(car.peer_id, car.pos)


func local_peer_id() -> int:
	if not multiplayer.has_multiplayer_peer():
		return 0
	return multiplayer.get_unique_id()


func _hud_text(me: CarState) -> String:
	var head := _status
	if not _connected and _retry_in > 0.0:
		head += " — nouvelle tentative dans %d s" % ceili(_retry_in)

	var lines := ["projet-6TT  —  %s" % head]
	lines.append("pilotes en piste : %d" % _net.remote_cars.size())
	if me != null:
		lines.append("tour %d   %d km/h" % [me.lap, roundi(absf(me.speed) * 0.42)])
	lines.append("")
	lines.append("fleches : diriger / accelerer / freiner")
	return "\n".join(lines)
