## Client de jeu : se connecte au serveur, envoie les commandes du joueur,
## affiche l'etat renvoye par le serveur.
##
## Tourne dans l'editeur comme dans le navigateur (export Web). Le port vise est
## celui PUBLIE par Docker (6604), pas le port interne du conteneur.
##
## La connexion est retentee en boucle : le serveur de jeu peut redemarrer
## (rebuild, `docker compose restart`) sans qu'il faille recharger la page.
extends Node2D

## Port publie sur l'hote par docker compose. Surchargeable par `?port=` dans
## l'URL de la page, pour coller a une valeur modifiee dans .env.
const DEFAULT_PORT := 6604
## Delai avant une nouvelle tentative de connexion.
const RETRY_SECONDS := 3.0

var _peer: WebSocketMultiplayerPeer
var _net: Node
var _status := "demarrage..."
var _url := ""
var _connected := false
var _retry_in := 0.0

var _cars_view: Node2D
var _hud: Label
var _camera: Camera2D
## Positions lissees pour le rendu : le serveur envoie 30 instantanes/s, l'ecran
## affiche souvent plus, donc on interpole entre deux instantanes.
var _smoothed: Dictionary = {}


func _ready() -> void:
	_net = get_parent().get_node("Net")

	var track_view := preload("res://client/track_view.gd").new()
	track_view.name = "TrackView"
	add_child(track_view)

	_cars_view = preload("res://client/cars_view.gd").new()
	_cars_view.name = "CarsView"
	_cars_view.client = self
	add_child(_cars_view)

	_camera = Camera2D.new()
	_camera.zoom = Vector2(0.85, 0.85)
	add_child(_camera)
	_camera.make_current()

	# Trace ponctuelle : confirme que les RPC du serveur sont bien recus et
	# decodes. Visible dans la console du navigateur comme dans le terminal.
	_net.snapshot_received.connect(_on_first_snapshot, CONNECT_ONE_SHOT)

	# Les signaux vivent sur la MultiplayerAPI, pas sur le pair : on les branche
	# une seule fois, et AVANT toute tentative — en local la connexion aboutit
	# parfois avant la fin de _ready().
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	_build_hud()
	_try_connect()


func _on_first_snapshot() -> void:
	print("[6TT] premier instantane recu — %d voiture(s) en piste"
			% _net.remote_cars.size())


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	_hud = Label.new()
	_hud.position = Vector2(18, 14)
	_hud.add_theme_font_size_override("font_size", 16)
	_hud.add_theme_color_override("font_color", Color("#e2e8f0"))
	_hud.add_theme_color_override("font_outline_color", Color("#0b0e14"))
	_hud.add_theme_constant_override("outline_size", 6)
	layer.add_child(_hud)


# --- Connexion ---------------------------------------------------------------

## Un pair WebSocket ayant echoue n'est pas reutilisable : on en cree un neuf a
## chaque tentative.
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


## Relance une tentative quand le pair est retombe a l'etat deconnecte. On ne
## touche a rien tant qu'une connexion est en cours (CONNECTION_CONNECTING).
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


## Dans le navigateur, on passe par la MEME origine que la page (Caddy relaie
## /ws vers le serveur Godot) : un seul port est ouvert par le navigateur, ce qui
## evite les blocages sur une connexion vers un autre port. `?port=NNNN` force au
## besoin une connexion directe au serveur de jeu, utile pour diagnostiquer.
## Hors navigateur (editeur, ligne de commande), on vise directement le port
## publie sur la machine locale.
func _server_url() -> String:
	if not OS.has_feature("web"):
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

	# window.location.host inclut deja le port de la page.
	var host_port := str(JavaScriptBridge.eval("window.location.host", true))
	return "%s://%s/ws" % [scheme, host_port]


# --- Boucle ------------------------------------------------------------------

func _process(delta: float) -> void:
	_update_connection(delta)

	_net.local_input = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_down", "ui_up"),
	)

	_update_smoothing(delta)
	_cars_view.queue_redraw()

	var me: CarState = _net.remote_cars.get(local_peer_id())
	if me != null:
		_camera.position = _smoothed.get(me.peer_id, me.pos)

	_hud.text = _hud_text(me)


## Rapproche les positions affichees des positions serveur, sans jamais devenir
## la source de verite.
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
