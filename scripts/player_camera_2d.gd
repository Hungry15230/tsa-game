extends Camera2D

@export var target: CharacterBody2D
@export var rotation_speed: float = 5.0

func _process(delta: float) -> void:
	if target:
		# Smoothly match the player's global rotation
		global_rotation = lerp_angle(global_rotation, target.global_rotation, rotation_speed * delta)
