extends Node
class_name AnimationComponent

@export_subgroup("Nodes")
@export var sprite: AnimatedSprite2D

func flip_animation(is_flipped: bool):
	sprite.flip_h = is_flipped
	
func play_animation(animation_name: String):
	sprite.play(animation_name)
