extends Node
class_name MovementComponent

var speed: int
var jump_velocity: int


@export var ground_deacc: float = 16.0
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
	
func h_movement_with_acc(body: CharacterBody2D, direction: float) -> void:
	if abs(direction * speed) < abs(body.velocity.x):
		body.velocity.x = move_toward(body.velocity.x, direction * speed, ground_deacc if body.is_on_floor() else air_deacc)
	else: 
		body.velocity.x = direction * speed
	
func handle_knockback(body: CharacterBody2D, direction: Vector2, force: float):
	if body.velocity.y > 0 and force > 0 and direction[1] < 0.25:
		body.velocity.y = 0
	body.velocity += direction * force
	
	
func velocity_cap(body: CharacterBody2D):
	var velocity = body.velocity
	if velocity.x > PlayerVariables.velocity_cap or velocity.x < PlayerVariables.velocity_cap * -1:
		if velocity.x > 0:
			velocity.x = PlayerVariables.velocity_cap
		else:
			velocity.x = PlayerVariables.velocity_cap * -1
	if velocity.y > PlayerVariables.velocity_cap or velocity.y < PlayerVariables.velocity_cap * -1:
		if velocity.y > 0:
			velocity.y = PlayerVariables.velocity_cap
		else:
			velocity.y = PlayerVariables.velocity_cap * -1
	body.velocity = velocity
