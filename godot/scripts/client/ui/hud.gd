## Interface tête haute (CanvasLayer indépendant du monde).
class_name Rac6ttHud
extends CanvasLayer

@onready var _status: Label = $Margin/StatusLabel


func set_status_text(text: String) -> void:
	_status.text = text
