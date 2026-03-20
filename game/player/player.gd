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


const THROTTLE_MAX :=  4
const THROTTLE_MIN := -1.5

func _ready() -> void:
	%ThrottleGauge.min_value = THROTTLE_MIN
	%ThrottleGauge.max_value = THROTTLE_MAX

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	var throttle_input = Input.get_axis("throttle_down", "throttle_up")
	throttle = clamp(throttle + acceleration * delta * throttle_input, THROTTLE_MIN, THROTTLE_MAX)
	%ThrottleGauge.set_value_no_signal(throttle)
	if abs(throttle) < 0.25 and throttle_input == 0:
		throttle = lerp(throttle, 0.0, 0.1)
		if abs(throttle) < 0.01:
			throttle = 0
			throttle_this_step = 0
	#print(throttle)
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
	var depth : float = abs(%AimTargetCenter.position.z)
	#if $RayCast3D.is_colliding():
		#depth = $RayCast3D.get_collider().global_position.distance_to(global_position)
	var target_pos :Vector3=  %PlayerCamera.project_position(mouse_pos, depth)
	if target_pos.distance_to(%AimTargetCenter.global_position) <= 4:
		%AimTarget.global_position = lerp(%AimTarget.global_position, target_pos, 0.4 *delta)
		$RayCast3D.look_at(%AimTarget.global_position)
	
	
	#%AimTarget.position.x = ( get_viewport().get_mouse_position().x - get_viewport().get_visible_rect().size.x * 0.5 ) * 3 / get_viewport().get_visible_rect().size.x
	#%AimTarget.position.y = (-get_viewport().get_mouse_position().y - get_viewport().get_visible_rect().size.y * 0.5 ) * 3 / get_viewport().get_visible_rect().size.y
	#%AimTarget.position.y += 7
	#%AimTarget.position.z = -10
	%WeaponSwivelRight.look_at(%AimTarget.global_position)
	%WeaponSwivelLeft.look_at(%AimTarget.global_position)
	
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
	if event.is_action_pressed("interact"):
		if current_item:
			handle_interaction(current_item)
	if event.is_action_pressed("shoot"):
		if $RayCast3D.get_collider() is Bird:
			$RayCast3D.get_collider().is_hit = true


func handle_interaction(item : Item):
	match item.interaction_type:
		Item.InteractionType.NPCDialogue:
			print("[F] talk to %s" % item.tech_id)
		Item.InteractionType.ItemPickup:
			print("[F] %s pick up " % item.tech_id)
	


var current_item : Item = null:
	set(value):
		current_item = value
		if value:
			%InteractionLabel.text = value.tech_id
		else:
			%InteractionLabel.text = ""

func _on_interaction_range_area_entered(area: Area3D) -> void:
	if area is Item:
		current_item = area
		%InteractionLabel.text = area.tech_id


func _on_interaction_range_area_exited(area: Area3D) -> void:
	if area is Item:
		current_item = null
