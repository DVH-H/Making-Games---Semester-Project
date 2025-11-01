extends CharacterBody2D

class_name Bullet

@export_subgroup("Settings")
@export var knockback_force: float = 200
@export var damage: float = 5
@export var SPEED: int = 300

@onready var movementComponent: MovementComponent = $MovementComponent
var _direction: Vector2

func initialize(dir: Vector2):
	_direction = dir.normalized()
	rotate(dir.angle())
	
func _ready() -> void:
	movementComponent.set_speed(SPEED)
	
 
func _physics_process(delta: float) -> void:
	movementComponent.handle_movement(self, _direction)
	move_and_slide()
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i).get_collider()
		on_collision(collision)
		#if collision.name == "Enemy":
		#	print("do somthing")
	
func on_collision(collider):
	queue_free()
 
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
