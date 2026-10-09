extends Control


func _ready() -> void:
	%Title.text = ProjectSettings.get_setting("application/config/name", "Parcours Godot")
	%Body.text = ProjectSettings.get_setting("application/config/description", "")
