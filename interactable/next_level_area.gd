extends Interactable

@export var next_level: PackedScene

func interact():
	GameController.goto_scene(next_level)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.set_interactable(self)


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		body.remove_interactable()# Replace with function body.
