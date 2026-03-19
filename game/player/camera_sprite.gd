extends Sprite3D



@export var camera : Camera3D
#@export var marker : Marker3D
#var start_offset : Vector3

#func _ready() -> void:
	#marker.reparent(self)
	#if camera:
		#start_offset = global_position - camera.global_position


func _process(delta: float) -> void:
	if camera:
		texture = camera.get_viewport().get_texture()
		#camera.global_position = global_position + start_offset
		#camera.look_at(marker.global_position)
