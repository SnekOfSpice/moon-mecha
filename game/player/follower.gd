extends Node3D

@export var target : Node3D


var start_offset : Vector3
var start_rotation : Vector3

func _ready() -> void:
	if target:
		start_offset = target.global_position - global_position
		start_rotation = target.global_rotation - global_rotation

func _process(delta: float) -> void:
	if target:
		global_position = target.global_position + start_offset
		global_rotation = target.global_rotation + start_rotation
	
