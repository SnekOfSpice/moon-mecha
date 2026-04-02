extends Node3D
class_name GameWorld

const PATH := "res://game/terrain.tscn"

func _ready() -> void:
	spawn_birds(1)

func spawn_birds(amount : int):
	for i in amount:
		var bird := preload("res://game/npcs/bird/bird.tscn").instantiate()
		bird.position = %BirdSpawn.position
		bird.target = %BirdTarget
		add_child(bird)
		bird.hit_ground.connect(func(corpse : Bird):
			var item : Item = preload("res://game/items/item.tscn").instantiate()
			add_child(item)
			item.tech_id = "birdcarcass"
			item.global_position = corpse.global_position
			item.interaction_type = Item.InteractionType.ItemPickup
			)
		EventBus.bird_created.emit(bird)
