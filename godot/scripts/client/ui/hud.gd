## HUD texte — CanvasLayer au-dessus du monde (non affecté par la caméra 2D).
##
## `client.gd` met à jour le libellé chaque frame (connexion, tours, vitesse).
class_name Rac6ttHud
extends CanvasLayer

@onready var _status: Label = $Margin/StatusLabel


func set_status_text(text: String) -> void:
	_status.text = text
