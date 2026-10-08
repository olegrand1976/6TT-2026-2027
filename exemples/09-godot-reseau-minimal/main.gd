extends Node


func _ready() -> void:
	var net: Node = preload("res://net.gd").new()
	net.name = "Net"
	add_child(net)

	if _is_server():
		var server: Node = preload("res://server.gd").new()
		server.name = "Server"
		add_child(server)
	else:
		var client: Node2D = preload("res://client.gd").new()
		client.name = "Client"
		add_child(client)


static func _is_server() -> bool:
	var args := OS.get_cmdline_user_args()
	if args.has("--client"):
		return false
	if args.has("--server"):
		return true
	return DisplayServer.get_name() == "headless"
