@tool
extends Area3D
class_name Item


enum InteractionType {
	NPCDialogue,
	ItemPickup,
}

@export var interaction_type : InteractionType = InteractionType.NPCDialogue:
	set(value):
		interaction_type = value
		match interaction_type:
			InteractionType.NPCDialogue:
				%BodyCollider.shape.height = 3.5
				%BodyCollider.shape.radius = 1.2
			InteractionType.ItemPickup:
				%BodyCollider.shape.height = 1.5
				%BodyCollider.shape.radius = 0.3

@export var tech_id : String:
	set(value):
		tech_id = value
		if self is Item:
			if ResourceLoader.exists("res://game/items/moon_shard/%s.png" % tech_id):
				%Sprite.texture = load("res://game/items/moon_shard/%s.png" % tech_id)


func _on_visible_on_screen_notifier_3d_screen_entered() -> void:
	EventBus.item_entered_viewport.emit(self)


func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	EventBus.item_exited_viewport.emit(self)


func handle_hit():
	if interaction_type == InteractionType.NPCDialogue:
		queue_free()
	print(tech_id, " is hit")
