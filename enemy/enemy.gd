extends CharacterBody2D
class_name enemy
#@export_subgroup("Nodes")

@onready var gravity_component: GravityComponent = $Gravity
@onready var movement_component: MovementComponent = $MovementComponent
@onready var chase_timer: Timer = $detection_area/chase_timer
@onready var attack_timer: Timer = $attack_cd_timer #cooldown 
@onready var animation_node: AnimatedSprite2D = $AnimatedSprite2D
@onready var sound_component: SoundComponent = $SoundComponent

@export_subgroup("Movement")
@export var speed = 60
@export var stop_at_edge: bool = true
@export var patrol_array: Array[Vector2]
@export var jump_force = 3000
var player_chase = false
var attack_cd_ready = true
var in_attack_range = false
@onready var player = get_tree().current_scene.get_node("Player")

@export var damage_sound: AudioStreamPlayer
@export var death_sound: AudioStreamPlayer

enum {
	STANDBY,
	AGGRO,
	SEARCH,
	ATTACK,
	DAMAGED,
	DYING
}

var state = STANDBY

@onready var left_ray = $LeftRayCast2D
@onready var right_ray = $RightRayCast2D
@onready var detection_area: Area2D = $detection_area
@onready var attack_area: Area2D = $attack_area
@export_subgroup("Stats")
@export var health = 30
var dir: Vector2 = Vector2.RIGHT
#var is_dying = false

var patrol_direction: float = 1.0
var patrol_timer: float = 0.0
var patrol_wait_time: float = 2.0


var current_patrol_index: int = 0

var last_flip_time: float = 0.0
var look_direction: float = 1.0

var search_timer: float = 0.0
var search_duration: float = 3.0

@export var damage: float = 20

func _ready() -> void:
	movement_component.set_speed(speed)
	movement_component.set_jump_velocity(jump_force)
	chase_timer.timeout.connect(_on_chase_timer_timeout)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)
	animation_node.animation_finished.connect(_on_animated_sprite_2d_animation_finished)

func do_state_behaviour(delta):
	var direction = 0.0
	if state == DYING:
		pass
	elif state == DAMAGED:
		pass
	elif state == ATTACK:
		direction = ATTACK_behaviour(delta)
	else:
		if state == STANDBY:
			direction = STANDBY_behaviour(delta)
		if state == SEARCH:
			direction = SEARCH_behaviour(delta)
		if state == AGGRO:
			direction = AGGRO_behaviour()
	return direction

func attack_area_direction(direction: float):
	if Vector2(direction, 0) != Vector2.ZERO:
		dir = Vector2(direction, 0)
		if direction > 0:
			attack_area.scale.x = 1
		else:
			attack_area.scale.x = -1

func _physics_process(delta: float) -> void:
	var direction = do_state_behaviour(delta)
	gravity_component.handle_gravity(self, delta)
	movement_component.h_movement_with_acc(self, direction)
	movement_component.velocity_cap(self)
	handle_animations(direction)
	check_collisions()
	move_and_slide()
	
func is_at_edge(direction: float) -> bool:
	if direction > 0:  # Moving right
		return not right_ray.is_colliding()
	elif direction < 0:  # Moving left
		return not left_ray.is_colliding()
	return false
	
func handle_animations(direction: float) -> void:
	# Only do looping animations
	if state == DYING:
		#sound_component.play_sound(death_sound)
		return
	elif state == ATTACK:
		return
	elif  state == DAMAGED:
		sound_component.play_sound(damage_sound) #damage sound placeholder
		return
	#if not is_on_floor():
		#if velocity.y > 0:
			#animation_node.play("fall")
		#else:
			#animation_node.play("jump")
	if direction != 0:
		animation_node.flip_h = (direction < 0)
		animation_node.play("walk")
	else:
		animation_node.play("idle")

func _on_detection_area_body_entered(body: Node2D) -> void:
	if state == DYING:
		return
	if not player:
		player = body
	state = AGGRO
	player_chase =  true 
	#attack_cd_ready = false
	attack_timer.start()
	chase_timer.stop()

func _on_detection_area_body_exited(body: Node2D) -> void:
	if state == DYING:
		return
	chase_timer.start() 


	
func take_damage(dmg: int) -> void:
	if state == DYING:
		return
	health = health - dmg
	state = DAMAGED
	animation_node.play("take_damage")
	movement_component.set_speed(speed)
	if health <= 0:
		die()

func die():
	animation_node.play("death")
	sound_component.play_sound(death_sound)
	state = DYING
	velocity.x = 0
	player_chase = false
	
func _on_chase_timer_timeout() -> void:
	if state == DYING:
		return
	player_chase = false
	state = SEARCH
	
func _on_attack_timer_timeout() -> void:
	if state == DYING:
		return
	attack_cd_ready = true

func STANDBY_behaviour(delta: float) -> float:
	if len(patrol_array) > 0:
		return patrol()
	return 0
	

func AGGRO_behaviour() -> float:
	if player and player_chase:
		var direction = 1 if player.position.x > position.x else -1
		attack_area_direction(direction)
		if is_at_edge(direction) and is_on_floor():
			if stop_at_edge:
				return 0
			movement_component.handle_jump(self)
		return direction
	#state = SEARCH
	return 0

func SEARCH_behaviour(delta: float) -> float:
	search_timer += delta
	if search_timer < search_duration:
		return stand_guard(delta)
	else:
		search_timer = 0
		patrol_timer = 0
		#state = STANDBY
		#current_patrol_target = patrol_point1  # Return to start point
		return 0
	
func patrol():
	var current_patrol_target = patrol_array[current_patrol_index]
	var distance_to_target = abs(global_position.x - current_patrol_target.x) #.distance_to(current_patrol_target)
	if distance_to_target < 50.0:  
		current_patrol_index += 1
		current_patrol_index = wrap(current_patrol_index, 0, len(patrol_array))
	var direction = sign(current_patrol_target.x - global_position.x)
	if stop_at_edge and is_on_floor() and is_at_edge(direction):
		return 0
	return direction
	
func stand_guard(delta: float) -> float:
	if state == DYING:
		return 0
	last_flip_time += delta
	
	if last_flip_time >= 1.0:
		look_direction *= -1
		animation_node.flip_h = (look_direction < 0)
		last_flip_time = 0
	return 0 

func check_collisions():
	if state == DYING:
		return
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i).get_collider()
		if collision:
			if collision.name == "Player":
				collision.take_damage(damage)

 
func ATTACK_behaviour(_delta) -> float:
	attack_timer.start()
	attack_cd_ready = false
	animation_node.play("attack")
	return 0

func _on_animated_sprite_2d_animation_finished() -> void:
	if animation_node.animation == "death":
		queue_free()
	if animation_node.animation == "take_damage":
		state = AGGRO
		player_chase = true
		if not player: 
			player = get_tree().current_scene.get_node("Player")
	if animation_node.animation == "attack":
		state = AGGRO 


func _on_attack_area_body_entered(body: Node2D) -> void:
	if not state == DYING and attack_cd_ready:
		state = ATTACK
	in_attack_range = true


func _on_attack_area_body_exited(body: Node2D) -> void:
	if not state == DYING:
		in_attack_range = false
