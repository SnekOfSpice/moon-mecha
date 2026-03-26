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

var trackerL : OnScreenTracker
func _ready() -> void:
	%ThrottleGaugeBack.min_value = THROTTLE_MIN
	%ThrottleGaugeBack.max_value = 0
	%ThrottleGaugeBack.custom_minimum_size.x = abs(THROTTLE_MIN) * 40
	%ThrottleGaugeForward.min_value = 0
	%ThrottleGaugeForward.max_value = THROTTLE_MAX
	%ThrottleGaugeForward.custom_minimum_size.x = abs(THROTTLE_MAX) * 40
	
	for marker : Marker3D in %WeaponRaycastR.get_children():
		%MainScreenVP.create_tracker(marker, true).mode = OnScreenTracker.Mode.Rangefinder

	for marker : Marker3D in %WeaponRaycastL.get_children():
		%MainScreenVP.create_tracker(marker, true).mode = OnScreenTracker.Mode.Rangefinder

	await get_tree().process_frame
	%CockpitScreenMain.set_viewport(%MainScreenVP)
	%CockpitScreenL.set_viewport(%LeftVP)
	%CockpitScreenR.set_viewport(%RightVP)
	
	#mech_mode = MechMode.Roaming


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	var throttle_input : float = Input.get_axis("throttle_down", "throttle_up")
	
	throttle = clamp(throttle + acceleration * delta * throttle_input, THROTTLE_MIN, THROTTLE_MAX)
	%ThrottleGaugeBack.set_value_no_signal(-throttle+THROTTLE_MIN)
	%ThrottleGaugeForward.set_value_no_signal(throttle)
	%ThrottleNeutralCheckBox.set_pressed_no_signal(throttle == 0)
	%ThrottleLabel.visible = throttle != 0
	var s = "-" if sign(throttle) == -1 else " "
	%ThrottleLabel.text = "%s%0.1f" % [s, abs(throttle)]
	if abs(throttle) < 0.25 and throttle_input == 0:
		throttle = lerp(throttle, 0.0, 0.1)
		if abs(throttle) < 0.01:
			throttle = 0
			#throttle_this_step = 0
	#print(throttle)
	rotate_y(TURN_SPEED * turn_dir)
	
	var curve_val := 0.0
	if throttle != 0 or step_progress > 0:
		is_stepping = true
		var old_prog = step_progress
		step_progress = wrapf(step_progress + delta * step_speed, 0, 1)
		if old_prog > step_progress:
			Sound.play_sfx("stomp") # credit https://freesound.org/people/Artninja/sounds/789754/
			if throttle == 0:
				step_progress = 0
				is_stepping = false
				throttle_this_step = 0
			if is_stepping:
				throttle_this_step = throttle
		curve_val = step_curve.sample(step_progress)
	$cockpit.position.y = cockpit_position.y + curve_val * max_step_offset
	curve_val *= sign(throttle_this_step) * sqrt(sqrt(abs(throttle_this_step)))
	
	var direction := (transform.basis * Vector3(0, 0, -curve_val))
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	#print(throttle, velocity.length())

#var last_collider : Node3D


#func _process(delta: float) -> void:
	

	
	
	
	# RESET
	#%WeaponSwivelLeft.look_at(Vector3.FORWARD.rotated(Vector3.UP,rotation.y) * 2000)

#var relative : Vector2 = Vector2.ZERO
	
var turn_dir : float


		

func _unhandled_input(event: InputEvent) -> void:
	#if event is InputEventMouseMotion:
		#relative = event.relative
	turn_dir = -Input.get_axis("turn_left", "turn_right")
	if event.is_action_pressed("brake"):
		throttle = 0
	if event.is_action_pressed("interact"):
		if current_item:
			handle_interaction(current_item)
	if event.is_action_pressed("safety_left"):
		%AimManagerL.safety_enabled = not %AimManagerL.safety_enabled
		Sound.play_sfx("switch1")
	if event.is_action_pressed("safety_right"):
		%AimManagerR.safety_enabled = not %AimManagerR.safety_enabled
		Sound.play_sfx("switch1")
	# not that fun actually
	#if event.is_action_pressed("switch_mode"):
		##if velocity.length() > 0:
			##notify("can only switch mode when velocity is 0")
			##return
		##if not %AimManagerL.is_steady():
			##notify("steady left arm")
			##return
		##if not %AimManagerR.is_steady():
			##notify("steady right arm")
			##return
		#if mech_mode == MechMode.Roaming:
			#mech_mode = MechMode.Shooting
		#elif mech_mode == MechMode.Shooting:
			#mech_mode = MechMode.Roaming


func notify(message : String) -> void:
	print("MAKE NOTIFS PRETTY")
	var notif := Label.new()
	notif.add_theme_font_size_override("font_size", 30)
	notif.text = message
	var timer := get_tree().create_timer(5)
	timer.timeout.connect(notif.queue_free)
	%Notifications.add_child(notif)


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


func _on_aim_manager_r_shoot() -> void:
	var shot_valid : bool = %pistol2.request_shot()
	
	if not shot_valid:
		return
	
	if %WeaponRaycastR.get_collider():
		if %WeaponRaycastR.get_collider().has_method("handle_hit"):
			%WeaponRaycastR.get_collider().handle_hit()
	
	


func _on_aim_manager_l_shoot() -> void:
	var shot_valid : bool = %sniper2.request_shot()
	
	if not shot_valid:
		return
	
	if %WeaponRaycastL.get_collider():
		if %WeaponRaycastL.get_collider().has_method("handle_hit"):
			%WeaponRaycastL.get_collider().handle_hit()
