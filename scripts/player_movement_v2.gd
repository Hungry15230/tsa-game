extends CharacterBody2D

@export var speed := 100.0
@export var decceleration := 10
@export var jump_velocity := -300.0
@export var rotation_speed := 5.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
# Rays
@onready var ray_left: RayCast2D = $RayLeft
@onready var ray_left_cliff: RayCast2D = $RayLeftCliff
@onready var ray_center: RayCast2D = $RayCenter
@onready var ray_right: RayCast2D = $RayRight
@onready var ray_right_cliff: RayCast2D = $RayRightCliff

var gravity_direction = Vector2.DOWN
var inside_gravitational_field := true

func _ready() -> void:
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_axis("game_left", "game_right")
	var target_normal := Vector2.ZERO
	var ground_detected = ray_center.is_colliding() or ray_left.is_colliding() or ray_right.is_colliding()
	var physically_grounded = ground_detected or is_on_floor()
	
	if inside_gravitational_field:
		# Inner Corners
		if input_dir > 0: # Moving right
			if ray_right.is_colliding():
				var right_normal = ray_right.get_collision_normal()
				# If ray hits inner wall, aka angle change > 45
				if right_normal.dot(up_direction) < 0.7:
					target_normal = right_normal # switches priority to wall
		elif input_dir < 0: # moving left
			if ray_left.is_colliding():
				var left_normal = ray_left.get_collision_normal()
				# change priority when wall detected
				if left_normal.dot(up_direction) < 0.7:
					target_normal = left_normal
		# fallback for no inner corners
		if target_normal == Vector2.ZERO and ray_center.is_colliding():
			target_normal = ray_center.get_collision_normal()
		# outer corners
		var just_wrapped_outer_corner := false
		if target_normal == Vector2.ZERO and not ground_detected:
			if input_dir > 0 and ray_left_cliff.is_colliding():
				target_normal = ray_left_cliff.get_collision_normal()
				just_wrapped_outer_corner = true
			elif input_dir < 0 and ray_right_cliff.is_colliding():
				target_normal = ray_right_cliff.get_collision_normal()
				just_wrapped_outer_corner = true
	
		# If a valid surface normal was found, swap
		if target_normal != Vector2.ZERO:
			var old_up = up_direction
			up_direction = target_normal.normalized()
			gravity_direction = -up_direction
			
			if just_wrapped_outer_corner:
				# zero out velocity when swapping
				var velocity_away_from_floor = velocity.project(up_direction)
				if velocity_away_from_floor.dot(up_direction) > 0:
					velocity -= velocity_away_from_floor
				# slight pull to floor
				velocity += gravity_direction * speed * 0.5
				# ensure player is against floor imediately
				global_position += gravity_direction * 2.0
		

	if inside_gravitational_field:
		# Add the gravity.
		if not physically_grounded:
			# get_gravity().length() is the magnitude (length) of the vector so it's not an x and y
			velocity += gravity_direction * get_gravity() * delta
	else:
		up_direction = Vector2.UP
		gravity_direction = Vector2.ZERO

	# rotate player
	var target_rotation = up_direction.angle() + PI/2
	global_rotation = lerp_angle(global_rotation, target_rotation, rotation_speed * delta)

	# keep controls inline with player rotation
	var local_right := up_direction.orthogonal() * -1.0 # 90 degrees to the wall normal, without the -1 it points left

	var gravity_velocity = velocity.project(gravity_direction)
	
	if input_dir:
		# flip local_right based on input direction
		velocity = (local_right * input_dir * speed) + gravity_velocity
	else:
		# Decelerate along the local surface
		var motion_velocity = velocity.project(local_right)
		motion_velocity = motion_velocity.move_toward(Vector2.ZERO, speed * decceleration * delta)
		velocity = motion_velocity + gravity_velocity

	# Handle jump.
	if Input.is_action_just_pressed("game_jump") and is_on_floor():
		# Away from surface normal
		velocity = up_direction * -jump_velocity
	
	move_and_slide()
