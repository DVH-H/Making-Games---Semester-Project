extends Node
class_name MovementComponent

@export_subgroup("Settings")
@export var speed = 100
@export var jump_velocity = 350

func handle_horizontal_movement(body: PhysicsBody2D, horizontal_direction: float) -> void:
	body.velocity.x = horizontal_direction * speed

func handle_jump(body: PhysicsBody2D) -> void:
	body.velocity.y = jump_velocity * -1 # is negative, as negative y is up in godot
	
func handle_movement(body: PhysicsBody2D, direction: Vector2) -> void:
	body.velocity = direction * speed
	
