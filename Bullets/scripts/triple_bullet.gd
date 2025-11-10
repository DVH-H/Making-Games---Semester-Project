extends Bullet

var _bullet = preload("res://Bullets/prefabs/bullet.tscn")


func initialize(dir: Vector2):
	super(dir)
	var b1 := _bullet.instantiate()
	var b2 := _bullet.instantiate()
	get_tree().root.add_child(b1)
	get_tree().root.add_child(b2)
	b1.global_position = global_position
	b2.global_position = global_position
	var dir1 = Vector2.from_angle(dir.angle() + PI * 0.1)
	var dir2 = Vector2.from_angle(dir.angle() - PI * 0.1)
	b1.initialize(dir1)
	b2.initialize(dir2)

func on_collision(collider):
	if collider.name == "LevelTileMap":
		queue_free()
	#queue_free()
