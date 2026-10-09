## Logs périodiques serveur (Timer dans `heartbeat_monitor.tscn`).
## Utile en Docker : voir qu'il y a des pilotes sans ouvrir le jeu.
extends Node

const INTERVAL_SECONDS := 15.0

@onready var _timer: Timer = $Timer

var _net: Node


func configure(net: Node) -> void:
	_net = net
	_timer.wait_time = INTERVAL_SECONDS
	if not _timer.timeout.is_connected(_on_timeout):
		_timer.timeout.connect(_on_timeout)
	_timer.start()


func _on_timeout() -> void:
	if _net == null:
		return
	var laps := 0
	for peer_id in _net.cars:
		laps = maxi(laps, _net.cars[peer_id].lap)
	print("[6TT] heartbeat pilotes=%d meilleur_tour=%d" % [_net.cars.size(), laps])
