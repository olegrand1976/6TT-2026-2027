## Pièce de voiture : lit les specs via le `Rac6ttCarView` propriétaire de la scène.
class_name CarPart
extends Node2D


func _car_view() -> Rac6ttCarView:
	var view := owner as Rac6ttCarView
	if view != null:
		return view
	var parts := get_parent()
	if parts != null:
		return parts.get_parent() as Rac6ttCarView
	return null


func refresh() -> void:
	queue_redraw()
