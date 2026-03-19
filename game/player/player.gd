extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

const TURN_SPEED := 0.05


@export var step_curve : Curve

var step_speed := 0.9
var max_step_offset := 0.35
var throttle := 0.0
var acceleration := 3.1

var step_progress := 0.0

@onready var cockpit_position : Vector3 = $cockpit.position

var is_stepping := false
var throttle_this_step := 0.0
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	throttle = clamp(throttle + acceleration * delta * Input.get_axis("throttle_down", "throttle_up"), -3, 3)
	
	
	rotate_y(TURN_SPEED * turn_dir)
	
	var curve_val := 0.0
	if throttle != 0 or step_progress > 0:
		is_stepping = true
		var old_prog = step_progress
		step_progress = wrapf(step_progress + delta * step_speed, 0, 1)
		if old_prog > step_progress:
			if throttle == 0:
				step_progress = 0
				is_stepping = false
				throttle_this_step = 0
			if is_stepping:
				throttle_this_step = throttle
		curve_val = step_curve.sample(step_progress)
	$cockpit.position.y = cockpit_position.y + curve_val * max_step_offset
	curve_val *= sign(throttle_this_step) * sqrt(abs(throttle_this_step))
	
	var direction := (transform.basis * Vector3(0, 0, -curve_val))
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	#print(throttle, velocity.length())


func _process(delta: float) -> void:
	
	var relsize  :Vector2= %MainScreenSprite.texture.get_size() * %PlayerCamera.global_position.distance_to(%MainScreenSprite.global_position)
	
	var left : float = %PlayerCamera.unproject_position(%TopL.global_position).x
	var right : float = %PlayerCamera.unproject_position(%TopR.global_position).x
	var top : float = %PlayerCamera.unproject_position(%TopR.global_position).y
	var bottom : float = %PlayerCamera.unproject_position(%BottomR.global_position).y
	
	var screen_size := get_viewport().get_visible_rect().size
	var left_right_distance := right - left
	var ratio := Vector2(
		screen_size.x / (right - left),
		screen_size.y /( bottom - top),
	)
	
	var mouse_pos := %PlayerCamera.get_viewport().get_mouse_position()
	if mouse_pos.x < right and mouse_pos.x > left and mouse_pos.y > top and mouse_pos.y < bottom:
		#print("aim")
		var range = right - left
		var a = (mouse_pos.x - left) / range
		var rangeb = bottom - top
		var b = (mouse_pos.y - top) / rangeb
		#print(Vector2(a, b))
		%AimTarget.global_position = %PlayerCamera.project_position(Vector2(a, b) * screen_size, 20)
		print($RayCast3D.get_collider())
	
	#%AimTarget.position.x = ( get_viewport().get_mouse_position().x - get_viewport().get_visible_rect().size.x * 0.5 ) * 3 / get_viewport().get_visible_rect().size.x
	#%AimTarget.position.y = (-get_viewport().get_mouse_position().y - get_viewport().get_visible_rect().size.y * 0.5 ) * 3 / get_viewport().get_visible_rect().size.y
	#%AimTarget.position.y += 7
	#%AimTarget.position.z = -10
	%WeaponSwivelRight.look_at(%AimTarget.global_position)
	
	#printt(
		#%PlayerCamera.unproject_position(%MainScreenSprite.global_position),
		#(get_viewport().get_mouse_position() - relsize * 0.5) / relsize,
		#%PlayerCamera.global_position.distance_to(%MainScreenSprite.global_position),
		#get_viewport().get_mouse_position()
	#)
	
var turn_dir : float

func _unhandled_input(event: InputEvent) -> void:
	turn_dir = -Input.get_axis("turn_left", "turn_right")
	if event.is_action_pressed("brake"):
		throttle = 0


func _on_interaction_range_area_entered(area: Area3D) -> void:
	if area is InteractionArea:
		%InteractionLabel.text = area.tech_id
		print(area.tech_id)


func _on_interaction_range_area_exited(area: Area3D) -> void:
	if area is InteractionArea:
		%InteractionLabel.text = ""
