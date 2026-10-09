## Représentation visuelle d'une voiture (une par pilote).
##
## La scène `car_view.tscn` contient les sprites (sans script) sous `Parts/`.
## Ce script applique `CarSpecs` (taille) et la couleur dérivée du `peer_id`.
##
## Appelé par `cars_layer.gd` à chaque snapshot réseau.
class_name Rac6ttCarView
extends Node2D

## Taille des PNG dans `assets/car/` (pixels) — sert à convertir en unités monde.
const TEX_BODY := Vector2(52.0, 28.0)
const TEX_NOSE := Vector2(20.0, 28.0)
const TEX_WHEEL := 16.0
const TEX_RING := 64.0

@export var specs: CarSpecs

var paint_color := Color.WHITE
var is_local_player := false

@onready var _body: Sprite2D = $Parts/Body/Sprite2D
@onready var _nose: Sprite2D = $Parts/Nose/Sprite2D
@onready var _wheel_fl: Sprite2D = $Parts/Wheels/FrontLeft
@onready var _wheel_fr: Sprite2D = $Parts/Wheels/FrontRight
@onready var _wheel_rl: Sprite2D = $Parts/Wheels/RearLeft
@onready var _wheel_rr: Sprite2D = $Parts/Wheels/RearRight
@onready var _ring: Sprite2D = $Parts/LocalRing/Sprite2D


func _ready() -> void:
	if specs == null:
		specs = preload("res://resources/cars/default_car.tres") as CarSpecs
	for spr in [_body, _nose, _ring, _wheel_fl, _wheel_fr, _wheel_rl, _wheel_rr]:
		if spr != null:
			spr.centered = true
	_refresh_visuals()


## Position / angle **serveur** (plus lissage côté client).
func sync_transform(world_pos: Vector2, heading: float) -> void:
	position = world_pos
	rotation = heading


func update_appearance(car: CarState, is_local: bool) -> void:
	var color := CarState.color_for(car.peer_id)
	if color == paint_color and is_local == is_local_player:
		return
	paint_color = color
	is_local_player = is_local
	_refresh_visuals()


func _refresh_visuals() -> void:
	if specs == null or _body == null:
		return
	_body.modulate = paint_color
	_body.scale = Vector2(specs.body_length / TEX_BODY.x, specs.body_width / TEX_BODY.y)

	var nose_len := specs.body_length * 0.38
	var nose_h := specs.body_width * 0.9
	_nose.modulate = paint_color.lightened(specs.nose_lighten)
	_nose.scale = Vector2(nose_len / TEX_NOSE.x, nose_h / TEX_NOSE.y)
	_nose.position = Vector2(specs.body_length * 0.32, 0.0)

	var wheel_scale := specs.wheel_radius * 2.0 / TEX_WHEEL
	var wheel_color := paint_color.darkened(0.35)
	var wheel_scale_v := Vector2.ONE * wheel_scale
	_apply_wheel(_wheel_fl, Vector2(specs.wheel_offset_forward, specs.wheel_offset_side), wheel_scale_v, wheel_color)
	_apply_wheel(_wheel_fr, Vector2(specs.wheel_offset_forward, -specs.wheel_offset_side), wheel_scale_v, wheel_color)
	_apply_wheel(_wheel_rl, Vector2(-specs.wheel_offset_forward, specs.wheel_offset_side), wheel_scale_v, wheel_color)
	_apply_wheel(_wheel_rr, Vector2(-specs.wheel_offset_forward, -specs.wheel_offset_side), wheel_scale_v, wheel_color)

	_ring.visible = is_local_player
	if is_local_player:
		var diameter := specs.body_length * specs.local_ring_radius_factor * 2.0
		_ring.scale = Vector2.ONE * (diameter / TEX_RING)
		_ring.modulate = Color(1, 1, 1, 0.85)


func _apply_wheel(spr: Sprite2D, pos: Vector2, scale_v: Vector2, color: Color) -> void:
	spr.position = pos
	spr.scale = scale_v
	spr.modulate = color
