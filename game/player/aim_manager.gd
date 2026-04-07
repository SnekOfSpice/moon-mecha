extends Node3D


signal shoot()

var tracker : OnScreenTracker
var tracker_rangefinder : OnScreenTracker

var safety_enabled := true:
	set(value):
		safety_enabled = value
		if tracker:
			if safety_enabled:
				tracker.modulate = tracker.COLOR_CROSSHAIR
			else:
				tracker.modulate = tracker.COLOR_ARMED

@export var tracker_vp : SubViewport
var aim_target_virtual : Node3D
var aim_target_gun : Node3D
var aim_speed : float = 10
var aim_sensitivity : float = 0.7
#@export var safety_aim_sensitivity : float = 0.5
@export var aim_action : String
@export var player_camera : Camera3D
@export var gun_camera : Camera3D
@export var vp_camera : Camera3D
@export var weapon_swivel : Node3D
@export var weapon_tech_id : String
var depth := 50:
	set(value):
		depth = value
		if not is_inside_tree():
			return
		await get_tree().process_frame
		var target_pos : Vector3 = vp_camera.project_position(tracker.position, depth)
		aim_target_virtual.global_position  = target_pos
		aim_target_gun.global_position  = target_pos
@export var move_swivel := true
var last_mouse_pos : Vector2


var active := true:
	set(value):
		active = value
		if tracker:
			tracker.visible = active
		if tracker_rangefinder:
			tracker_rangefinder.visible = active

@export_enum("Left", "Right") var ammo_label_side
func generate_ui():
	if tracker: tracker.queue_free()
	if tracker_rangefinder: tracker_rangefinder.queue_free()
	aim_target_virtual = Node3D.new()
	add_child(aim_target_virtual)
	aim_target_gun = Node3D.new()
	add_child(aim_target_gun)
	
	tracker = tracker_vp.create_tracker(aim_target_virtual, true)
	tracker.weapon_tech_id = weapon_tech_id
	tracker.aim_depth = depth
	tracker.main_crosshair = move_swivel
	if ammo_label_side == 0:
		tracker.crosshair_side = tracker.CROSSHAIR_SIDE_LEFT
	if ammo_label_side == 1:
		tracker.crosshair_side = tracker.CROSSHAIR_SIDE_RIGHT
	
	tracker.mode = OnScreenTracker.Mode.Crosshair
	tracker_rangefinder = tracker_vp.create_tracker(aim_target_gun, true)
	tracker_rangefinder.mode = OnScreenTracker.Mode.Rangefinder
	tracker_rangefinder.rangefinder_offset = gun_camera.position.z
	await get_tree().process_frame
	
	reset_aim(true)


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("reset_aim"):
		reset_aim()
		Sound.play_sfx("ping", false)

func reset_aim(reset_gun := false):
	var target_pos : Vector3 = vp_camera.project_position(tracker_vp.size * 0.5, depth)
	aim_target_virtual.global_position  = target_pos
	if reset_gun:
		aim_target_gun.global_position  = target_pos

func _process(delta: float) -> void:
	if Parser.line_reader:
		if not Parser.line_reader.terminated:
			return
	if not active:
		return
	var mouse_pos := player_camera.get_viewport().get_mouse_position()
	#mouse_pos.x = clamp(mouse_pos.x, 60, 640 - 60)
	#mouse_pos.y = clamp(mouse_pos.y, 0, 340)
	#last_mouse_pos.x = clamp(last_mouse_pos.x, 60, 640 - 60)
	#last_mouse_pos.y = clamp(last_mouse_pos.y, 0, 340)
	
	
	#print(tracker.position.x + mouse_pos.x - last_mouse_pos.x)
	
	if tracker.position.x + mouse_pos.x - last_mouse_pos.x < 13:
		if last_mouse_pos.x >= mouse_pos.x:
			last_mouse_pos.x = mouse_pos.x
	if tracker.position.x + mouse_pos.x - last_mouse_pos.x > 230:
		if last_mouse_pos.x <= mouse_pos.x:
			last_mouse_pos.x = mouse_pos.x
	if tracker.position.y + mouse_pos.y - last_mouse_pos.y < 40:
		if last_mouse_pos.y >= mouse_pos.y:
			last_mouse_pos.y = mouse_pos.y
	if tracker.position.y + mouse_pos.y - last_mouse_pos.y > 160:
		if last_mouse_pos.y <= mouse_pos.y:
			last_mouse_pos.y = mouse_pos.y
	
	var target_pos : Vector3 =  vp_camera.project_position(mouse_pos, depth)
	var target_pos_last : Vector3 =  vp_camera.project_position(last_mouse_pos, depth)
		
	var dir := target_pos - target_pos_last
	dir *= aim_sensitivity
	
	if Input.is_action_pressed(aim_action) and safety_enabled:
		aim_target_virtual.global_position += dir
	if Input.is_action_just_pressed(aim_action) and not safety_enabled:
			shoot.emit()
	
	
	
	if move_swivel:
		var speed_fac := 1.0
		#if not safety_enabled:
			#speed_fac *= safety_aim_sensitivity
		aim_target_gun.global_position = aim_target_gun.global_position.move_toward(aim_target_virtual.global_position, aim_speed * delta * speed_fac)
		weapon_swivel.look_at(aim_target_gun.global_position)
	
	
	last_mouse_pos = mouse_pos


func is_steady() -> bool:
	return aim_target_gun.global_position.distance_to(aim_target_virtual.global_position) <= 0.01
