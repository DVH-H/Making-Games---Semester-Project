extends Node2D

var collision_list: Array = []


@export var duration = 0.05
var _time_passed = 0.0

@export var force = 400



func _physics_process(delta: float) -> void:
	_time_passed += delta
	if _time_passed > duration:
		for body in collision_list:
			var direction = body.global_position - global_position
			body.velocity = force * direction
		queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player" and body not in collision_list:
		collision_list.append(body)
	if body.is_in_group("Enemy"):
		collision_list.append(body)
