## Point d'entree unique du projet.
##
## Le meme projet sert de serveur dedie ET de client : on choisit le role au
## demarrage. En headless (conteneur Docker) c'est le serveur ; partout ailleurs
## (editeur, export Web) c'est le client.
##
## `Net` est ajoute en premier et TOUJOURS, des deux cotes : les RPC de Godot
## sont routes par chemin de noeud, donc l'emetteur et le destinataire doivent
## se trouver au meme endroit dans l'arbre (/root/Main/Net).
extends Node


func _ready() -> void:
	var net: Node = preload("res://net.gd").new()
	net.name = "Net"
	add_child(net)

	if is_dedicated_server():
		var server: Node = preload("res://server/server.gd").new()
		server.name = "Server"
		add_child(server)
	else:
		var client: Node = preload("res://client/client.gd").new()
		client.name = "Client"
		add_child(client)


## Par defaut le role se deduit de l'affichage : pas d'affichage (conteneur
## Docker) = serveur. `-- --client` ou `-- --server` force le choix, ce qui
## permet notamment de lancer un client sans fenetre pour tester le reseau :
##   godot --headless --path . -- --client
static func is_dedicated_server() -> bool:
	var args := OS.get_cmdline_user_args()
	if args.has("--client"):
		return false
	if args.has("--server"):
		return true
	return DisplayServer.get_name() == "headless"
