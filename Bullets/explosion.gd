extends Node2D

var collision_list: Array = []

@export var duration = 0.8 #set this based on esxlosion sound duration
@export var push_time = 0.1
var has_pushed: bool = false
var _time_passed = 0.0

@export var force = 400
@export var damage = 5
var source

@export var sound: AudioStreamPlayer

func _physics_process(delta: float) -> void:
	_time_passed += delta
	if _time_passed > push_time and not has_pushed:
		for body in collision_list:
			var direction = body.global_position - global_position
			body.velocity = force * direction
			if not body == source:
				body.take_damage(damage)
			#if body.is_in_group("Enemy"):
			#	body.take_damage(damage)
		has_pushed = true
	if _time_passed > duration:
		queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body not in collision_list:
		collision_list.append(body)
	if body.is_in_group("Enemy"):
		collision_list.append(body)
