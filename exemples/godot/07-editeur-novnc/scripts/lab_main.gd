extends Control


func _ready() -> void:
	var title: String = ProjectSettings.get_setting("application/config/name", "Lab Rac6TT")
	var desc: String = ProjectSettings.get_setting("application/config/description", "")
	%Title.text = title
	%Body.text = desc
