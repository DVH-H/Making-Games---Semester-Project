extends Node2D

const BULLET = preload("res://components/bullet.tscn")

@onready var muzzle: Marker2D = $Marker2D

func _process(delta: float) -> void:
	var stick_dir = Vector2(
		Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left"),
		Input.get_action_strength("aim_down")  - Input.get_action_strength("aim_up")
	)
	look_at(global_position + stick_dir)
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -1
	else:
		scale.y = 1
	if Input.is_action_just_pressed("shoot"):
		var bullet_instance = BULLET.instantiate()
		get_tree().root.add_child(bullet_instance)
		bullet_instance.global_position = muzzle.global_position
		bullet_instance.rotation = rotation
