extends Node
class_name InputComponent

func get_horizontal_input() -> float:
	return Input.get_axis("move_left", "move_right")
	
	
func get_input_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

func get_jump_input() -> bool:
	return Input.is_action_just_pressed("jump")
