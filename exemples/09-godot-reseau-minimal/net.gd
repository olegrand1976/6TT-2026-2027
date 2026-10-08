## Couche RPC minimale — le nœud DOIT s'appeler Net et rester sous Main.
class_name Net
extends Node

const TICK_RATE := 20.0
const PORT := 8970

var is_server := false
## peer_id -> Vector2 (positions pédagogiques, pas la voiture Rac6TT)
var positions: Dictionary = {}

var _accum := 0.0


func _process(delta: float) -> void:
	if not is_server:
		return
	_accum += delta
	if _accum >= 1.0 / TICK_RATE:
		_accum = 0.0
		broadcast()


@rpc("any_peer", "call_remote", "unreliable")
func submit_position(pos: Vector2) -> void:
	if not is_server:
		return
	var id := multiplayer.get_remote_sender_id()
	positions[id] = pos


@rpc("authority", "call_local", "unreliable")
func sync_state(state: Dictionary) -> void:
	positions = state


func broadcast() -> void:
	if is_server and multiplayer.multiplayer_peer:
		sync_state.rpc(positions)


func register_peer(id: int) -> void:
	positions[id] = Vector2(randf_range(-120.0, 120.0), randf_range(-80.0, 80.0))


func unregister_peer(id: int) -> void:
	positions.erase(id)
