extends CharacterBody2D

@onready var gravity_component: GravityComponent = $Gravity
@onready var input_controller: InputComponent = $InputController
@onready var animation_controller: AnimationComponent = $AnimationController
@onready var movement_component: MovementComponent = $MovementComponent
@onready var gun = $Gun

@onready var max_health: int = PlayerVariables.default_max_health
@onready var current_health: int = PlayerVariables.current_health


var speed: int = 100
var jump_velocity: int = 350
var coyote_time = 0.2
var _aim_direction: Vector2 = Vector2(1,0)

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
	if input_controller.get_jump_input() and (is_on_floor() or coyote_time_counter > 0.0):
		movement_component.handle_jump(self)
		coyote_time_counter = 0.0  # consume coyote time so it can't be reused mid-air
	
	# Aiming and shooting
	var aim_dir = input_controller.get_aim_input().normalized()
	if aim_dir != Vector2.ZERO:
		_aim_direction = aim_dir
	gun.aim(_aim_direction)
	if Input.is_action_just_pressed("shoot"):
		var force = gun.shoot(_aim_direction)
		#velocity += (_aim_direction * -1) * force
		movement_component.handle_knockback(self, _aim_direction * -1, force)
	movement_component.horizontal_movement_with_acc(self, input_controller.get_horizontal_input())
	if Input.is_action_just_pressed("reload"):
		gun.reload_all_to_loadout()
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
	
func take_damage(dmg: int):
	current_health -= dmg
	PlayerVariables.current_health = current_health
	if current_health <= 0:
		# play death animation then
		GameController.reload_from_checkpoint()
		
