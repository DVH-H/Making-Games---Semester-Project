extends Node
class_name MovementComponent

var speed: int
var jump_velocity: int

@export_subgroup("Acceleration")
@export var ground_acc: float = 6.0
@export var ground_deacc: float = 8.0
@export var air_acc: float = 10.0
@export var air_deacc: float = 3.0

func set_speed(s: int):
	speed = s
	
func set_jump_velocity(jump_v: int):
	jump_velocity = jump_v

func handle_horizontal_movement(body: PhysicsBody2D, horizontal_direction: float) -> void:
	body.velocity.x = horizontal_direction * speed

func handle_jump(body: PhysicsBody2D) -> void:
	body.velocity.y = jump_velocity * -1 # is negative, as negative y is up in godot
	
func handle_movement(body: PhysicsBody2D, direction: Vector2) -> void:
	body.velocity = direction * speed
	
func horizontal_movement_with_acc(body: CharacterBody2D, direction: float) -> void:
	var velocity_change: float = 0.0
	if body.is_on_floor():
		velocity_change = ground_acc if direction != 0 else ground_deacc
	else:
		velocity_change = air_acc if direction != 0 else air_deacc
	body.velocity.x = move_toward(body.velocity.x, direction * speed, velocity_change)
	
