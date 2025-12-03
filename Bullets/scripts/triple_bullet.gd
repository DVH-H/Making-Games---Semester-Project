extends Bullet

var _bullet = preload("res://Bullets/prefabs/triple_bullet.tscn")
var _spawned_side_bullets := false


func initialize(dir: Vector2):
	super(dir)
	# Only spawn side bullets for the main triple bullet, not the spawned ones
	if not _spawned_side_bullets:
		_spawned_side_bullets = true
		var b1 := _bullet.instantiate()
		var b2 := _bullet.instantiate()
		# Mark these as already spawned to prevent infinite recursion
		b1._spawned_side_bullets = true
		b2._spawned_side_bullets = true
		get_tree().root.add_child(b1)
		get_tree().root.add_child(b2)
		b1.global_position = global_position
		b2.global_position = global_position
		var dir1 = Vector2.from_angle(dir.angle() + PI * 0.1)
		var dir2 = Vector2.from_angle(dir.angle() - PI * 0.1)
		b1.initialize(dir1)
		b2.initialize(dir2)
