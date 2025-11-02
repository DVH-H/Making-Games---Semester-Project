extends Interactable

func interact():
	CheckpointManager.set_checkpoint(GameController.current_scene, position)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.set_interactable(self)


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		body.remove_interactable()
