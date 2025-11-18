extends Bullet

@export var explosion: PackedScene

var _has_collided: bool = false


func on_collision(collider):
	super(collider)
	if not _has_collided:
		_has_collided = true
		var bullet := explosion.instantiate()
		get_tree().root.add_child(bullet)
		bullet.global_position = global_position
		#queue_free()
	# do damage here
