extends SubViewport


var trackers_by_item := {}

func _ready() -> void:
	EventBus.item_entered_viewport.connect(on_item_entered_viewport)
	EventBus.item_exited_viewport.connect(on_item_exited_viewport)
	EventBus.bird_created.connect(on_bird_created)


func on_item_entered_viewport(item : Item):
	var tracker := create_tracker(item)
	trackers_by_item[item] = tracker


func create_tracker(target : Node3D, immediately_visible := false) -> OnScreenTracker:
	var tracker := OnScreenTracker.create(immediately_visible)
	$CanvasLayer.add_child(tracker)
	tracker.camera = %Camera3D
	tracker.target = target
	return tracker


func on_item_exited_viewport(item : Item):
	if trackers_by_item.has(item):
		trackers_by_item.get(item).queue_free()


func on_bird_created(bird : Bird):
	create_tracker(bird)
