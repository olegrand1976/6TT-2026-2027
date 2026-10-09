## Assemble les pièces visuelles ; les specs pilotent dimensions et futurs profils.
class_name CarView
extends Node2D

@export var specs: CarSpecs

var paint_color := Color.WHITE
var is_local_player := false

var _parts: Array[CarPart] = []


func _ready() -> void:
	if specs == null:
		specs = preload("res://resources/cars/default_car.tres") as CarSpecs
	_collect_parts()
	for part in _parts:
		part.refresh()


func _collect_parts() -> void:
	_parts.clear()
	var parts_root := get_node_or_null("Parts")
	if parts_root == null:
		return
	for child in parts_root.get_children():
		if child is CarPart:
			_parts.append(child as CarPart)


func sync_transform(world_pos: Vector2, heading: float) -> void:
	position = world_pos
	rotation = heading


func update_appearance(car: CarState, is_local: bool) -> void:
	var color := CarState.color_for(car.peer_id)
	if color == paint_color and is_local == is_local_player:
		return
	paint_color = color
	is_local_player = is_local
	for part in _parts:
		part.refresh()
