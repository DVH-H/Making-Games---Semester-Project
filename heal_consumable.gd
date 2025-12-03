extends Area2D




func _on_body_entered(body: Node2D) -> void:
	body.heal(20)
	queue_free()
