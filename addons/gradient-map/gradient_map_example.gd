extends Node2D



func _ready() -> void:
	%GradientMap.set_gradient_map(load("res://addons/gradient-map/default.tres"), 1, 0)
	
	get_tree().create_timer(2).timeout.connect(func():
		%GradientMap.set_gradient_map(load("res://addons/gradient-map/1.tres"))
		)
		
