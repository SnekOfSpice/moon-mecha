extends Node2D
class_name OnScreenTracker

var camera : Camera3D
var target : Node3D

var immediately_visible := false

var weapon_tech_id : String
var aim_depth : int
var main_crosshair : bool


static func create(p_immediately_visible := false) -> OnScreenTracker:
	var tracker := preload("res://game/player/on_screen_tracker.tscn").instantiate()
	tracker.immediately_visible = p_immediately_visible
	return tracker
	


func _ready() -> void:
	if not immediately_visible:
		hide()
		var timer := get_tree().create_timer(0.5)
		timer.timeout.connect(func():
			show()
			Sound.play_sfx("beep", false)
		)
	Data.property_changed.connect(on_property_changed)
	


func on_property_changed(
	property : String,
	new_value : Variant,
	old_value : Variant,
):
	if not is_crosshair:
		return
	if property == "ammo.%s" % weapon_tech_id:
		%AmmoLabel.text = str(new_value)

func _enter_tree() -> void:
	#if immediately_visible:
		#show()
	if target:
		target.tree_exiting.connect(queue_free)

const FULL_SCALE_LOWER_BOUND := 20
const MIN_SCALE_UPPER_BOUND := 200
func _process(delta: float) -> void:
	if not camera:
		free()
		return
	if not target:
		free()
		return
	
	position = camera.unproject_position(target.global_position)
	
	%AimDepthLabel.visible = is_crosshair
	%AimDepthLabel.text = str(aim_depth)
	
	if is_crosshair:
		if main_crosshair: scale = Vector2.ONE
		else: scale = Vector2.ONE * 0.33
	else:
		var s = (camera.global_position.distance_to(target.global_position) - FULL_SCALE_LOWER_BOUND) / MIN_SCALE_UPPER_BOUND
		scale.x = clamp(1-s, 0, 1)
		scale.y = clamp(1-s, 0, 1)
	
	%DistanceLabel.text = str(int(camera.global_position.distance_to(target.global_position)))


var is_crosshair := false:
	set(value):
		is_crosshair = value
		%DistanceLabel.visible = not is_crosshair
		%AmmoLabel.visible = is_crosshair
		if is_crosshair:
			%Sprite2D.texture = load("res://game/ui/crosshairs.png")
			%AmmoLabel.text = str(Data.of("ammo.%s" % weapon_tech_id))
		else:
			%Sprite2D.texture = load("res://game/ui/tracker.png")
