extends Node3D
class_name Gun


@export var muzzle_position : Marker3D
@export var shoot_sfx : AudioStream
@export var gun_stats : GunStats


func _ready() -> void:
	time_since_last_shot = gun_stats.time_between_shots

var time_since_last_shot := 0.0
func _process(delta: float) -> void:
	time_since_last_shot += delta


## returns true if the shot happened
func request_shot() -> bool:
	if time_since_last_shot < gun_stats.time_between_shots:
		return false
	
	shoot_fx()
	var sfx := AudioStreamPlayer3D.new()
	sfx.stream = shoot_sfx
	sfx.position = muzzle_position.global_position
	sfx.bus = "SFX"
	sfx.autoplay = true
	add_child(sfx)
	time_since_last_shot = 0.0
	return true


func shoot_fx():
	for mat : GPUParticles3D in %MuzzleFlash.get_children():
		mat.one_shot = true
		mat.emitting = true
