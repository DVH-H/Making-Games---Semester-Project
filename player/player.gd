extends CharacterBody2D

# Signals
signal health_changed(new_health: int, max_health: int)

@onready var gravity_component: GravityComponent = $Gravity
@onready var input_controller: InputComponent = $InputController
@onready var animation_controller: AnimationComponent = $AnimationController
@onready var movement_component: MovementComponent = $MovementComponent
@onready var sound_component: SoundComponent = $SoundComponent
@onready var gun = $Gun

@onready var max_health: int = PlayerVariables.max_health
@onready var current_health: int = PlayerVariables.current_health

var _reset_timer := 0.0
var _reset_held := false
var reset_hold_time = 1

@onready var speed: int = PlayerVariables.speed
@onready var jump_velocity: int = PlayerVariables.jump_velocity
@onready var coyote_time: float = PlayerVariables.coyote_time
@onready var invulnerability_time: float = PlayerVariables.invulnerability_time
var invulnerability_current_time: float = 0.0
var is_invulnerable: bool = false
var _aim_direction: Vector2 = Vector2(-0.01,1)

var _interactable: Interactable = null

@export var footsteps_sound: AudioStreamPlayer
@export var jump_sound: AudioStreamPlayer
@export var land_sound: AudioStreamPlayer
@export var damage_sound: AudioStreamPlayer
@export var death_sound: AudioStreamPlayer
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
	add_to_group("Player")
	# Clean up any orphaned loadout menus from previous scene instances
	_cleanup_orphaned_loadout_menus()
	movement_component.set_speed(speed)
	movement_component.set_jump_velocity(jump_velocity)
	CheckpointManager.spawn_player_at_checkpoint(self)
	# Emit initial health for UI
	health_changed.emit(current_health, max_health)

func _physics_process(delta: float) -> void:
	update_coyote_time_counter(delta)
	if is_invulnerable:
		invulnerability_current_time -= delta
		if invulnerability_current_time < 0.0:
			is_invulnerable = false
		
		
	gravity_component.handle_gravity(self, delta)
	if input_controller.get_jump_input() and (is_on_floor() or coyote_time_counter > 0.0):
		movement_component.handle_jump(self)
		coyote_time_counter = 0.0  # consume coyote time so it can't be reused mid-air
		sound_component.play_sound(jump_sound)
	
	# Aiming and shooting
	
	var aim_dir := Vector2.ZERO
	if len(Input.get_connected_joypads()) > 0:
		aim_dir = input_controller.get_aim_input().normalized()
	else:
		var mouse_pos: Vector2 = get_global_mouse_position()
		aim_dir = (mouse_pos - global_position).normalized()
	if aim_dir != Vector2.ZERO:
		_aim_direction = aim_dir
	gun.aim(_aim_direction)
	if Input.is_action_just_pressed("shoot") :
		var force = gun.shoot(_aim_direction)
		movement_component.handle_knockback(self, _aim_direction * -1, force)
	movement_component.h_movement_with_acc(self, input_controller.get_horizontal_input())
	if (Input.is_action_just_pressed("reload") and (is_on_floor() or coyote_time_counter > 0.0)):
		gun.reload_all_to_loadout()
	if Input.is_action_just_pressed("rotate_cylinder_forward"):
		gun._advance_cylinder()
	if Input.is_action_just_pressed("rotate_cylinder_backward"):
		gun._de_advance_cylinder()
	if Input.is_action_just_pressed("loadout_menu") and not _is_loadout_menu_open():
		_open_loadout_menu()
	elif Input.is_action_just_pressed("loadout_menu") and _is_loadout_menu_open():
		# Close the menu if it's already open
		var loadout_menu = get_tree().get_first_node_in_group("LoadoutMenu")
		if loadout_menu:
			loadout_menu.close_menu()
	# State machine. Also setting animations
	if is_on_floor():
		if state == FALLING: 
			sound_component.play_sound(land_sound)
		if velocity.x != 0:
			state = RUNNING
			sound_component.play_sound(footsteps_sound)
			if velocity.x > 0:
				animation_controller.play_animation("run_right")
			else:
				animation_controller.play_animation("run_left")
			#animation_controller.flip_animation(velocity.x >= 0)
		else:
			state = IDLE
			if "right" in $AnimatedSprite2D.animation:
				animation_controller.play_animation("idle_right")
			elif "left" in $AnimatedSprite2D.animation:
				animation_controller.play_animation("idle_left")
	else:
		if velocity.y > 0:
			state = FALLING
			if "right" in $AnimatedSprite2D.animation or velocity.x > 0:
				animation_controller.play_animation("fall_right")
			elif "left" in $AnimatedSprite2D.animation or velocity.x < 0:
				animation_controller.play_animation("fall_left")
			#animation_controller.play_animation("fall")
		else:
			state = JUMPING
			if "right" in $AnimatedSprite2D.animation or velocity.x > 0:
				animation_controller.play_animation("jump_right")
			elif "left" in $AnimatedSprite2D.animation or velocity.x < 0:
				animation_controller.play_animation("jump_left")
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
	movement_component.velocity_cap(self)
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
func take_damage(dmg: int):
	if not is_invulnerable:
		invulnerability_current_time = invulnerability_time
		is_invulnerable = true
		current_health -= dmg
		health_changed.emit(current_health, max_health)
		PlayerVariables.current_health = current_health
		sound_component.play_sound_noCheck(damage_sound) #change later to damage sound
		if current_health <= 0:
			# play death animation then
			# sound_component.play_sound_noCheck(death_sound) play death_sound
			GameController.reload_from_checkpoint()

func heal(amount: int):
	current_health = min(current_health + amount, max_health)
	PlayerVariables.current_health = current_health
	health_changed.emit(current_health, max_health)

func _reset_full():
	CheckpointManager.clear_checkpoint()
	GameController.reload_scene()

func _cleanup_orphaned_loadout_menus():
	# Remove any loadout menus that aren't children of the current player's CanvasLayer
	var canvas_layer = get_node_or_null("CanvasLayer")
	var all_menus = get_tree().get_nodes_in_group("LoadoutMenu")
	for menu in all_menus:
		if canvas_layer and menu.get_parent() != canvas_layer:
			# This menu is orphaned (from a previous scene or checkpoint)
			menu.queue_free()
		elif not canvas_layer and menu.get_parent() != get_tree().root:
			# No canvas layer exists but menu is in wrong place
			menu.queue_free()

func _open_loadout_menu():
	if not LoadoutManager:
		return
	
	# Get or create the loadout menu
	var loadout_menu = get_tree().get_first_node_in_group("LoadoutMenu") as LoadoutMenu
	if not loadout_menu or not is_instance_valid(loadout_menu):
		# Try to add to CanvasLayer so it follows the camera
		var canvas_layer = get_node_or_null("CanvasLayer")
		var parent = canvas_layer if canvas_layer else null
		loadout_menu = LoadoutManager.open_loadout_menu(get_tree(), parent)
		return
	# Toggle if already exists
	if loadout_menu.visible:
		loadout_menu.close_menu()
	else:
		loadout_menu.open_menu()

func _is_loadout_menu_open() -> bool:
	var loadout_menu = get_tree().get_first_node_in_group("LoadoutMenu")
	return loadout_menu != null and loadout_menu.visible
