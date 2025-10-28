extends CharacterBody2D
@export_subgroup("Nodes")
@export var gravity_component: GravityComponent
@export var movement_component: MovementComponent

@export_subgroup("Movement")
@export var speed = 60
var player_chase = false
var player = null

func _ready() -> void:
	movement_component.set_speed(speed)

func _physics_process(delta: float) -> void:
	gravity_component.handle_gravity(self, delta)
	if player_chase and player:
		var direction = sign(player.position.x - position.x)
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
	
func _on_detection_area_body_entered(body: Node2D) -> void:
	player = body
	player_chase =  true 

func _on_detection_area_body_exited(body: Node2D) -> void:
	player = null
	player_chase =  false 
