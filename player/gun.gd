extends Node2D

const BULLET = preload("res://Bullets/prefabs/knockback_bullet.tscn")
@onready var muzzle: Marker2D = $Marker2D


func shoot(direction):
	var bullet_instance = BULLET.instantiate()
	get_tree().root.add_child(bullet_instance)
	bullet_instance.initialize(direction)
	bullet_instance.global_position = muzzle.global_position
	return bullet_instance.knockback_force

func aim(dir):
	#Mostly for debugging
	var stick_dir = Vector2.ZERO
	if len(Input.get_connected_joypads()) < 0:
		var mouse_pos: Vector2 = get_global_mouse_position()
		stick_dir = (mouse_pos - global_position).normalized()
	else:
		stick_dir = dir
	look_at(global_position + stick_dir)
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -1
	else:
		scale.y = 1
	
		
