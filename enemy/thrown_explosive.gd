extends Debris

var explosion: PackedScene = load("res://Bullets/explosion.tscn")

func on_collision(collision):
	super(collision)
	var bullet := explosion.instantiate()
	get_tree().root.add_child(bullet)
	bullet.global_position = global_position
	bullet.source = source
	bullet.damage = 20
	#explosion_sound = bullet.sound
	#sound_component.play_sound(explosion_sound)
