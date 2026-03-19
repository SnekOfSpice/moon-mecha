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
	print(throttle, velocity.length())

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
