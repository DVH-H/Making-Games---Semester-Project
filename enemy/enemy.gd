extends CharacterBody2D
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

@onready var left_ray = $LeftRayCast2D
@onready var right_ray = $RightRayCast2D
var health = 30
var is_dying = false

func _ready() -> void:
	movement_component.set_speed(speed)
	chase_timer.timeout.connect(_on_chase_timer_timeout)
	death_timer.timeout.connect(_on_death_timer_timeout)

func _physics_process(delta: float) -> void:
	if is_dying:
		$AnimatedSprite2D.play("death")
		return

	gravity_component.handle_gravity(self, delta)
	if player_chase and player:
		var direction = sign(player.position.x - position.x)
		if is_on_floor() and is_at_edge(direction) and stop_at_edge:		
			direction = 0
		
		movement_component.handle_horizontal_movement(self, direction)
		
		if (direction < 0):
			$AnimatedSprite2D.flip_h = true
		else:
			$AnimatedSprite2D.flip_h = false	
		$AnimatedSprite2D.play("walk")				
	else:
		velocity.x = 0
		$AnimatedSprite2D.play("idle")
	
	move_and_slide()
	
func is_at_edge(direction: float) -> bool:
	if direction > 0:  # Moving right
		return not right_ray.is_colliding()
	elif direction < 0:  # Moving left
		return not left_ray.is_colliding()
	return false
	
func _on_detection_area_body_entered(body: Node2D) -> void:
	player = body
	player_chase =  true 
	chase_timer.stop()

func _on_detection_area_body_exited(body: Node2D) -> void:
	chase_timer.start() 

func _on_damage_area_body_entered(body: Node2D) -> void:
	if body is Bullet and not is_dying:
		print("bullet hit enemy") # Replace with function body.
		take_damage()
	
func take_damage() -> void:
	health = health - 10
	print("hit")
	if health <= 0:
		die()

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
