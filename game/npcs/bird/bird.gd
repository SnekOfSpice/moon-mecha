extends CharacterBody3D
class_name Bird

const SPEED = 5.0


var is_hit := false


var target : Node3D


signal hit_ground(corpse : Bird)


func _physics_process(delta: float) -> void:
	if not target:
		return
	# Add the gravity.
	if (not is_on_floor()) and is_hit:
		velocity += get_gravity() * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := global_position.direction_to(target.global_position)
	var dist := global_position.distance_to(target.global_position)
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#print(input_dir)
	if is_hit:
		if is_on_floor():
			velocity.x = 0
			velocity.z = 0
		else:
			velocity.x = direction.x * SPEED * 2
			velocity.z = direction.z * SPEED * 2
	elif dist <= SPEED:
		
		velocity.x = direction.x * dist
		velocity.z = direction.z * dist
	else:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	
	%Model.look_at(target.global_position)
	move_and_slide()
	if dist < 0.01:
		queue_free()


func _on_ground_detection_area_body_entered(body: Node3D) -> void:
	if body is StaticBody3D and is_hit:
		hit_ground.emit(self)
		queue_free()
