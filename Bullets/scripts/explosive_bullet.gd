extends Bullet

@export var explosion: PackedScene

var _has_collided: bool = false

@onready var sound_component: SoundComponent = $SoundComponent
var explosion_sound: AudioStreamPlayer

func on_collision(collider):
	super(collider)
	if not _has_collided:
		_has_collided = true
		var bullet := explosion.instantiate()
		get_tree().root.add_child(bullet)
		bullet.global_position = global_position
		explosion_sound = bullet.sound
		sound_component.play_sound(explosion_sound)
		#queue_free()
	# do damage here
