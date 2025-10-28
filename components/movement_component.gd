extends Node
class_name MovementComponent

var speed: int
var jump_velocity: int

func set_speed(s: int):
	speed = s
	
func set_jump_velocity(jump_v: int):
	jump_velocity = jump_v

func handle_horizontal_movement(body: CharacterBody2D, horizontal_direction: float) -> void:
	body.velocity.x = horizontal_direction * speed

func handle_jump(body: CharacterBody2D) -> void:
	body.velocity.y = jump_velocity * -1 # is negative, as negative y is up in godot
