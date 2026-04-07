extends Resource
class_name GunStats


@export var tech_id : String
@export var time_between_shots : float = 2.0

## how quickly the gun swivels
@export var aim_speed : float = 10.0
## how quickly the internal tracker moves
@export var aim_sensitivity : float = 0.5
@export var depth : int = 100
@export var ammo : int = 6
