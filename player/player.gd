extends CharacterBody2D
@export_subgroup("Nodes")
@export var gravity_component: GravityComponent
@export var input_controller: InputComponent
@export var animation_controller: AnimationComponent
@export var movement_component: MovementComponent

@export_subgroup("Movement")
@export var speed: int = 100
@export var jump_velocity: int = 350


# state machine
enum {
	IDLE,
	RUNNING,
	JUMPING,
	FALLING,
	WALLSLIDING
}
@onready var state = IDLE

func _ready() -> void:
	movement_component.set_speed(speed)
	movement_component.set_jump_velocity(jump_velocity)

func _physics_process(delta: float) -> void:
	gravity_component.handle_gravity(self, delta)
	movement_component.handle_horizontal_movement(self, input_controller.get_horizontal_input())
	if input_controller.get_jump_input() and is_on_floor():
		movement_component.handle_jump(self)
		
	# State machine. Also setting animations
	if is_on_floor():
		if velocity.x != 0:
			state = RUNNING
			animation_controller.play_animation("run")
			animation_controller.flip_animation(velocity.x < 0)
		else:
			state = IDLE
			animation_controller.play_animation("idle")
	else:
		if velocity.y > 0:
			state = FALLING
			animation_controller.play_animation("fall")
		else:
			state = JUMPING
			animation_controller.play_animation("jump")
		animation_controller.flip_animation(velocity.x < 0)
	
	move_and_slide()
	
