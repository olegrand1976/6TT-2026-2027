## Pièce de voiture : lit les specs via le `CarView` propriétaire de la scène.
class_name CarPart
extends Node2D


func _car_view() -> CarView:
	var view := owner as CarView
	if view != null:
		return view
	var parts := get_parent()
	if parts != null:
		return parts.get_parent() as CarView
	return null


func refresh() -> void:
	queue_redraw()
