extends Node3D
class_name Gun


enum FireResult {
	Success,
	OutOfAmmo,
	FireRate
}

@export var muzzle_position : Marker3D
@export var shoot_sfx : AudioStream
@export var gun_stats : GunStats


func _ready() -> void:
	time_since_last_shot = gun_stats.time_between_shots
	Data.apply("ammo.%s" % gun_stats.tech_id, gun_stats.ammo)

var time_since_last_shot := 0.0
func _process(delta: float) -> void:
	time_since_last_shot += delta


## returns true if the shot happened
func request_shot() -> FireResult:
	if time_since_last_shot < gun_stats.time_between_shots:
		return FireResult.FireRate
	
	if Data.of("ammo.%s" % gun_stats.tech_id) <= 0:
		return FireResult.OutOfAmmo
	
	shoot_fx()
	var sfx := AudioStreamPlayer3D.new()
	sfx.stream = shoot_sfx
	sfx.position = muzzle_position.global_position
	sfx.bus = "SFX"
	sfx.autoplay = true
	add_child(sfx)
	time_since_last_shot = 0.0
	Data.change_by("ammo.%s" % gun_stats.tech_id, -1)
	
	return FireResult.Success


func shoot_fx():
	for mat : GPUParticles3D in %MuzzleFlash.get_children():
		mat.one_shot = true
		mat.emitting = true


func get_camera_remote_transform() -> RemoteTransform3D:
	return %CameraRemoteTransform


func get_raycast() -> WeaponRaycast:
	return %WeaponRaycast


func get_rangefinder_markers():
	return get_raycast().get_children()
	
