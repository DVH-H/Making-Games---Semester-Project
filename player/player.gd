extends CharacterBody2D

@onready var gravity_component: GravityComponent = $Gravity
@onready var input_controller: InputComponent = $InputController
@onready var animation_controller: AnimationComponent = $AnimationController
@onready var movement_component: MovementComponent = $MovementComponent
@onready var gun = $Gun

@export_subgroup("Movement")
@export var speed: int = 100
@export var jump_velocity: int = 350
@export var coyote_time = 0.2
@export var reset_hold_time := 1.0  # seconds to count as "hold reset"
var _aim_direction: Vector2 = Vector2(1,0)

var _interactable = null
var _reset_timer := 0.0
var _reset_held := false

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
	movement_component.horizontal_movement_with_acc(self, input_controller.get_horizontal_input())
	if input_controller.get_jump_input() and (is_on_floor() or coyote_time_counter > 0.0):
		movement_component.handle_jump(self)
		coyote_time_counter = 0.0  # consume coyote time so it can't be reused mid-air
	
	# Aiming and shooting
	var aim_dir = input_controller.get_aim_input().normalized()
	if aim_dir != Vector2.ZERO:
		_aim_direction = aim_dir
	gun.aim(_aim_direction)
	if Input.is_action_just_pressed("shoot") and not _is_loadout_menu_open():
		velocity += (_aim_direction * -1) * gun.shoot(_aim_direction)
	if Input.is_action_just_pressed("reload"):
		gun.reload_all_to_loadout()
	if Input.is_action_just_pressed("loadout_menu"):
		_open_loadout_menu()
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
		
	if Input.is_action_pressed("reset"):
		_reset_timer += delta
		if _reset_timer >= reset_hold_time and not _reset_held:
			_reset_held = true
			_reset_full()
	elif Input.is_action_just_released("reset"):
		if not _reset_held:
			_reset_to_checkpoint()
		_reset_timer = 0.0
		_reset_held = false
	else:
		if _reset_timer > 0.0 and not _reset_held:
			_reset_timer = 0.0
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
	
func _reset_to_checkpoint():
	if CheckpointManager.has_checkpoint():
		GameController.reload_from_checkpoint()
	else:
		GameController.reload_scene()

func _reset_full():
	CheckpointManager.clear_checkpoint()
	GameController.reload_scene()

func _open_loadout_menu():
	# Find or create the loadout menu
	var loadout_menu = get_tree().get_first_node_in_group("LoadoutMenu")
	if not loadout_menu:
		# Create the loadout menu if it doesn't exist
		var loadout_menu_scene = preload("res://ui/LoadoutMenu.tscn")
		loadout_menu = loadout_menu_scene.instantiate()
		
		# Add to the player's CanvasLayer so it follows the camera
		var canvas_layer = get_node("CanvasLayer")
		if canvas_layer:
			canvas_layer.add_child(loadout_menu)
		else:
			# Fallback to root if CanvasLayer not found
			get_tree().root.add_child(loadout_menu)
		
		loadout_menu.add_to_group("LoadoutMenu")
		
		# Connect signals
		loadout_menu.loadout_applied.connect(_on_loadout_applied)
		loadout_menu.menu_closed.connect(_on_loadout_menu_closed)
	
	# Toggle the menu instead of just opening
	loadout_menu.toggle_menu()

func _on_loadout_applied(new_loadout: Array[PackedScene]):
	# Apply the new loadout to the gun
	gun.apply_current_loadout()

func _on_loadout_menu_closed():
	# Handle menu closing if needed
	pass

func _is_loadout_menu_open() -> bool:
	var loadout_menu = get_tree().get_first_node_in_group("LoadoutMenu")
	return loadout_menu != null and loadout_menu.visible
