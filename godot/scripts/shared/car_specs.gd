## Profil voiture (fichier `.tres` éditable dans Godot).
##
## Côté client : `car_view.gd` lit dimensions / apparence.
## Côté serveur : brancher la même Resource dans `CarPhysics.step(..., specs)` (TODO net.gd).
##
## Les défauts gameplay reprennent `CarPhysics` pour une seule source de vérité.
class_name CarSpecs
extends Resource

@export_group("Dimensions")
@export var body_length := 26.0
@export var body_width := 14.0
@export var wheel_radius := 3.0
@export var wheel_offset_forward := 8.0
@export var wheel_offset_side := 6.0

@export_group("Apparence")
@export var nose_lighten := 0.45
@export var local_ring_radius_factor := 0.85
@export var local_ring_width := 2.0

@export_group("Gameplay")
@export var max_speed := CarPhysics.MAX_SPEED
@export var max_reverse := CarPhysics.MAX_REVERSE
@export var accel := CarPhysics.ACCEL
@export var brake := CarPhysics.BRAKE
@export var turn_rate := CarPhysics.TURN_RATE
