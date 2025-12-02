extends CharacterBody2D

@onready var movement_component: MovementComponent = $MovementComponent
@onready var gravity: GravityComponent = $Gravity

var direction: float
var speed: float
var damage: float
@export var throw_arch_height: int = 3500
@export var throw_speed_multiplier: float = 0.85

func initialize(target_x: float, dmg: float) -> void:
	damage = dmg
	direction = 1 if target_x > global_position.x else -1
	speed = (global_position.x - target_x) * throw_speed_multiplier
	movement_component.set_speed(abs(speed))
	movement_component.set_jump_velocity(throw_arch_height)
	movement_component.handle_jump(self)
	movement_component.velocity_cap(self)

func _physics_process(delta: float) -> void:
	gravity.handle_gravity(self, delta)
	movement_component.handle_horizontal_movement(self, direction)
	movement_component.velocity_cap(self)
	move_and_slide()
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i).get_collider()
		if collision.name == "Player":
			collision.take_damage(damage)
		#print(collision.name)
		queue_free()
	
func destroy():
	queue_free()
