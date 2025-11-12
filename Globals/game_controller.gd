extends Node


var current_scene = null

func _ready():
	current_scene = get_tree().current_scene
	
func goto_scene(path):
	_deferred_goto_scene.call_deferred(path)

func reload_scene():
	get_tree().reload_current_scene()
	
func reload_from_checkpoint():
	PlayerVariables.current_health = PlayerVariables.max_health
	goto_scene(CheckpointManager._scene_path)

func _deferred_goto_scene(path):
	# It is now safe to remove the current scene.
	current_scene.free()

	# Load the new scene.
	var s = ResourceLoader.load(path)

	# Instance the new scene.
	current_scene = s.instantiate()

	# Add it to the active scene, as child of root.
	get_tree().root.add_child(current_scene)

	# Optionally, to make it compatible with the SceneTree.change_scene_to_file() API.
	get_tree().current_scene = current_scene
