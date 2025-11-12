extends CharacterBody2D
class_name enemy
@export_subgroup("Nodes")
@export var gravity_component: GravityComponent
@export var movement_component: MovementComponent
@export var chase_timer: Timer
@export var death_timer: Timer

@export_subgroup("Movement")
@export var speed = 60
@export var stop_at_edge: bool = true
var player_chase = false
var player = null

enum {
	STANDBY,
	AGGRO,
	SEARCH,
	ATTACK,
	DAMAGED
}

var state = STANDBY

@onready var left_ray = $LeftRayCast2D
@onready var right_ray = $RightRayCast2D
@export var health = 30
var is_dying = false

var patrol_direction: float = 1.0
var patrol_timer: float = 0.0
var patrol_wait_time: float = 2.0

@export var patrol_point1: Vector2 
@export var patrol_point2: Vector2
var current_patrol_target: Vector2

var last_flip_time: float = 0.0
var look_direction: float = 1.0

var search_timer: float = 0.0
var search_duration: float = 3.0

func _ready() -> void:
	movement_component.set_speed(speed)
	chase_timer.timeout.connect(_on_chase_timer_timeout)
	death_timer.timeout.connect(_on_death_timer_timeout)

	current_patrol_target = patrol_point2
		
func _physics_process(delta: float) -> void:
	if is_dying:
		$AnimatedSprite2D.play("death")
		return	
	var direction = 0
	
	if state == STANDBY:
		direction = STANDBY_behaviour(delta)
	if state == AGGRO:
		direction = AGGRO_behaviour()
	if state == SEARCH:
		direction = SEARCH_behaviour(delta)
	if state == ATTACK:
		direction = ATTACK_behaviour()
	if state == DAMAGED:
		direction = 0
		
	gravity_component.handle_gravity(self, delta)
	movement_component.handle_horizontal_movement(self, direction)
	
	handle_animations(direction)
	move_and_slide()
	
func is_at_edge(direction: float) -> bool:
	if direction > 0:  # Moving right
		return not right_ray.is_colliding()
	elif direction < 0:  # Moving left
		return not left_ray.is_colliding()
	return false
	
func handle_animations(direction: float) -> void:
	if is_dying:
		return
	if direction != 0:
		$AnimatedSprite2D.flip_h = (direction < 0)
		$AnimatedSprite2D.play("walk")
	else:
		$AnimatedSprite2D.play("idle")

func _on_detection_area_body_entered(body: Node2D) -> void:
	if is_dying:
		return
	state = AGGRO
	print("Activate AGGRO")
	player = body
	player_chase =  true 
	chase_timer.stop()

func _on_detection_area_body_exited(body: Node2D) -> void:
	if is_dying:
		return
	chase_timer.start() 

func _on_damage_area_body_entered(body: Node2D) -> void:
	if body is Bullet and not is_dying and player:
		print("bullet hit enemy")
		state = DAMAGED
		take_damage()
	
func take_damage() -> void:
	health = health - 10
	$AnimatedSprite2D.play("take_damage")
	print("hit")
	if health <= 0:
		die()
	else:
		state = AGGRO
		print("here")

func die():
	is_dying = true
	print("die")
	velocity.x = 0
	player_chase = false
	death_timer.start()	
	
func _on_chase_timer_timeout() -> void:
	player_chase = false
	player = null
	
func _on_death_timer_timeout() -> void:
	$AnimatedSprite2D.play("death")
	print("play dead")
	queue_free()

func STANDBY_behaviour(delta: float) -> float:
	patrol_timer += delta
	if patrol_timer < patrol_wait_time:
		return patrol()
	else:
		patrol_timer = 0
		patrol_direction *= -1
		return 0

func AGGRO_behaviour() -> float:
	if player and player_chase:
		var direction = sign(player.position.x - position.x)
		if stop_at_edge and is_on_floor() and is_at_edge(direction):
			return 0
		return direction
		
	print("Exit AGGRO enter SEARCH")
	state = SEARCH
	return 0

func SEARCH_behaviour(delta: float) -> float:
	search_timer += delta
	if search_timer < search_duration:
		return stand_guard(delta)
	else:
		search_timer = 0
		patrol_timer = 0
		state = STANDBY
		current_patrol_target = patrol_point1  # Return to start point
		print("SEARCH finished back to patrol")
		return 0
		
func ATTACK_behaviour():
	pass
	
func patrol():
	var distance_to_target = global_position.distance_to(current_patrol_target)
	if distance_to_target < 5.0:  
		if current_patrol_target == patrol_point1:
			current_patrol_target = patrol_point2
		else:
			current_patrol_target = patrol_point1
	var direction = sign(current_patrol_target.x - global_position.x)
	if stop_at_edge and is_on_floor() and is_at_edge(direction):
		return 0
	return direction
	
func stand_guard(delta: float) -> float:
	last_flip_time += delta
	
	if last_flip_time >= 1.0:
		print("Looking around")
		look_direction *= -1
		$AnimatedSprite2D.flip_h = (look_direction < 0)
		last_flip_time = 0
	return 0 
