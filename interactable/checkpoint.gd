extends Interactable
@onready var sound_component: SoundComponent = $SoundComponent
@export var check_sound: AudioStreamPlayer

func interact():
	#CheckpointManager.set_checkpoint(GameController.current_scene, position)
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("_open_loadout_menu"):
		player._open_loadout_menu()


func _on_area_2d_body_entered(body: Node2D) -> void:
	CheckpointManager.set_checkpoint(GameController.get_current_scene_path(), position)
	sound_component.play_sound(check_sound)
	if body.name == "Player":
		body.set_interactable(self)


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		body.remove_interactable()
