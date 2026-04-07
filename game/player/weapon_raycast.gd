extends RayCast3D
class_name WeaponRaycast


@export var crosshairs : TextureRect
@export var id_label : Label

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not crosshairs:
		return
	if not id_label:
		return
	
	var collider := get_collider()
	
	if not collider:
		crosshairs.hide()
		return
	crosshairs.show()
	
	
	var id := ""
	if collider is Item:
		match collider.interaction_type:
			Item.InteractionType.NPCDialogue:
				id = "Combatant"
			Item.InteractionType.ItemPickup:
				id = "Curio"
	elif collider is  Bird:
		id = "Traitor"
	elif collider is StaticBody3D:
		id = "Terrain"
	
	
	var distance := str(int(global_position.distance_to(get_collision_point())))
	
	id_label.text = "%s
	%s" % [id, distance]
