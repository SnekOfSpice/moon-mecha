extends SubViewport


var trackers_by_item := {}

func _ready() -> void:
	EventBus.item_entered_viewport.connect(on_item_entered_viewport)
	EventBus.item_exited_viewport.connect(on_item_exited_viewport)


func on_item_entered_viewport(item : Item):
	var tracker := preload("res://game/player/on_screen_tracker.tscn").instantiate()
	$CanvasLayer.add_child(tracker)
	tracker.camera = %Camera3D
	tracker.target = item
	trackers_by_item[item] = tracker


func on_item_exited_viewport(item : Item):
	if trackers_by_item.has(item):
		trackers_by_item.get(item).queue_free()
