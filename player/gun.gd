extends Node2D

const BULLET = preload("res://Bullets/prefabs/bullet.tscn")
@export var inputController: InputComponent
var _direction: Vector2 = Vector2(1,0)

@onready var muzzle: Marker2D = $Marker2D

func _process(delta: float) -> void:
	var stick_dir = inputController.get_aim_input()
	if stick_dir != Vector2.ZERO:
		_direction = stick_dir
	look_at(global_position + _direction)
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -1
	else:
		scale.y = 1
	if Input.is_action_just_pressed("shoot"):
		var bullet_instance = BULLET.instantiate()
		get_tree().root.add_child(bullet_instance)
		bullet_instance.initialize(_direction)
		bullet_instance.global_position = muzzle.global_position
