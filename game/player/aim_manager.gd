extends Node



var tracker : OnScreenTracker


@export var tracker_vp : SubViewport
@export var aim_target_virtual : Node3D
@export var aim_target_gun : Node3D
@export var aim_speed : float = 10
@export var aim_action : String
@export var player_camera : Camera3D
@export var vp_camera : Camera3D
@export var weapon_swivel : Node3D
@export var weapon_tech_id : String
@export var depth := 50
@export var max_depth := 250
var last_mouse_pos : Vector2

func _ready() -> void:
	tracker = tracker_vp.create_tracker(aim_target_virtual, true)
	tracker.weapon_tech_id = weapon_tech_id
	tracker.aim_depth = depth
	tracker.main_crosshair = depth == max_depth
	tracker.is_crosshair = true
	
	await get_tree().process_frame
	var mouse_pos := player_camera.get_viewport().get_mouse_position()
	var target_pos : Vector3 =  vp_camera.project_position(tracker_vp.size * 0.5, depth)
	aim_target_virtual.global_position  = target_pos
	aim_target_gun.global_position  = target_pos

func _process(delta: float) -> void:
	var mouse_pos := player_camera.get_viewport().get_mouse_position()
	mouse_pos.x = clamp(mouse_pos.x, 60, 640 - 60)
	mouse_pos.y = clamp(mouse_pos.y, 0, 340)
	last_mouse_pos.x = clamp(last_mouse_pos.x, 60, 640 - 60)
	last_mouse_pos.y = clamp(last_mouse_pos.y, 0, 340)
	
	
	#print(tracker.position.x + mouse_pos.x - last_mouse_pos.x)
	
	if tracker.position.x + mouse_pos.x - last_mouse_pos.x < 20:
		if last_mouse_pos.x >= mouse_pos.x:
			last_mouse_pos.x = mouse_pos.x
	if tracker.position.x + mouse_pos.x - last_mouse_pos.x > 210:
		if last_mouse_pos.x <= mouse_pos.x:
			last_mouse_pos.x = mouse_pos.x
	if tracker.position.y + mouse_pos.y - last_mouse_pos.y < 15:
		if last_mouse_pos.y >= mouse_pos.y:
			last_mouse_pos.y = mouse_pos.y
	if tracker.position.y + mouse_pos.y - last_mouse_pos.y > 150:
		if last_mouse_pos.y <= mouse_pos.y:
			last_mouse_pos.y = mouse_pos.y
	
	var target_pos : Vector3 =  vp_camera.project_position(mouse_pos, depth)
	var target_pos_last : Vector3 =  vp_camera.project_position(last_mouse_pos, depth)
		
	var dir := target_pos - target_pos_last
	
	
	if Input.is_action_pressed(aim_action):
		aim_target_virtual.global_position += dir
	
	aim_target_gun.global_position = aim_target_gun.global_position.move_toward(aim_target_virtual.global_position, aim_speed * delta)
	
	if depth == max_depth:
		weapon_swivel.look_at(aim_target_gun.global_position)
	
	
	last_mouse_pos = mouse_pos
	
	
