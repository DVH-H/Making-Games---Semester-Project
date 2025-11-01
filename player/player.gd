extends CharacterBody2D
@export_subgroup("Nodes")
@onready var gravity_component: GravityComponent = $Gravity
@export var input_controller: InputComponent
@export var animation_controller: AnimationComponent
@export var movement_component: MovementComponent
@export var coyote_time = 0.2

@export_subgroup("Movement")
@export var speed: int = 100
@export var jump_velocity: int = 350

var _interactable = null

# state machine
enum {
	IDLE,
	RUNNING,
	JUMPING,
	FALLING,
	WALLSLIDING
}
@onready var state = IDLE
var coyote_time_counter = 0.0

func _ready() -> void:
	movement_component.set_speed(speed)
	movement_component.set_jump_velocity(jump_velocity)
	CheckpointManager.spawn_player_at_checkpoint(self)

func _physics_process(delta: float) -> void:
	update_coyote_time_counter(delta)
	gravity_component.handle_gravity(self, delta)
	movement_component.handle_horizontal_movement(self, input_controller.get_horizontal_input())
	if input_controller.get_jump_input() and (is_on_floor() or coyote_time_counter > 0.0):
		movement_component.handle_jump(self)
		coyote_time_counter = 0.0  # consume coyote time so it can't be reused mid-air
		
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
	if _interactable != null and input_controller.get_interact_input():
		_interactable.interact()
	move_and_slide()
	
func update_coyote_time_counter(delta: float) -> void:
	if is_on_floor():
		coyote_time_counter = coyote_time
	else:
		coyote_time_counter -= delta 
		
func set_interactable(node: Interactable):
	_interactable = node

func remove_interactable():
	_interactable = null
	
