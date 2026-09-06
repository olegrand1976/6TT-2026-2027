## Rendu des voitures, redessine a chaque image depuis l'etat serveur lisse.
extends Node2D

const LENGTH := 26.0
const WIDTH := 14.0

var client: Node2D


func _draw() -> void:
	var net: Node = client.get_parent().get_node("Net")
	# Types annotes explicitement : `client` est un Node2D generique ici, donc
	# le moteur ne peut pas inferer le retour de ses methodes.
	var me: int = client.local_peer_id()

	for peer_id in net.remote_cars:
		var car: CarState = net.remote_cars[peer_id]
		var pos: Vector2 = client.smoothed_position(car)
		_draw_car(pos, car.heading, CarState.color_for(peer_id), peer_id == me)


func _draw_car(pos: Vector2, heading: float, color: Color, is_local: bool) -> void:
	var forward := Vector2(cos(heading), sin(heading))
	var side := forward.orthogonal()

	var body := PackedVector2Array([
		pos + forward * (LENGTH * 0.5) + side * (WIDTH * 0.5),
		pos + forward * (LENGTH * 0.5) - side * (WIDTH * 0.5),
		pos - forward * (LENGTH * 0.5) - side * (WIDTH * 0.5),
		pos - forward * (LENGTH * 0.5) + side * (WIDTH * 0.5),
	])
	draw_colored_polygon(body, color)

	# Museau plus clair : indique le sens de marche d'un coup d'oeil.
	var nose := PackedVector2Array([
		pos + forward * (LENGTH * 0.5) + side * (WIDTH * 0.5),
		pos + forward * (LENGTH * 0.5) - side * (WIDTH * 0.5),
		pos + forward * (LENGTH * 0.2) - side * (WIDTH * 0.5),
		pos + forward * (LENGTH * 0.2) + side * (WIDTH * 0.5),
	])
	draw_colored_polygon(nose, color.lightened(0.45))

	if is_local:
		draw_arc(pos, LENGTH * 0.85, 0.0, TAU, 32, Color.WHITE, 2.0, true)
