extends Node3D



func _ready() -> void:
	spawn_birds(1)

func spawn_birds(amount : int):
	for i in amount:
		var bird := preload("res://game/npcs/bird/bird.tscn").instantiate()
		bird.position = %BirdSpawn.position
		bird.target = %BirdTarget
		add_child(bird)
