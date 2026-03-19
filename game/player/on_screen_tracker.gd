extends Node2D


var camera : Camera3D
var target : Item


func _process(delta: float) -> void:
	if not camera:
		return
	if not target:
		return
	
	position = camera.unproject_position(target.global_position)
	var s = (camera.global_position.distance_to(target.global_position) - 200) / 2300
	scale.x = clamp(1-s, 0, 1)
	scale.y = clamp(1-s, 0, 1)
