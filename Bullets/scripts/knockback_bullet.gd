extends Bullet


func on_collision(collider):
	print("knockback bullet hit something")
	queue_free()
