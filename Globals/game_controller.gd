extends Node

var current_scene = null
var _last_known_scene_path: String = "res://game.tscn"  # set to your start scene

func _ready():
	current_scene = get_tree().current_scene
	if current_scene:
		_last_known_scene_path = current_scene.scene_file_path

func get_current_scene_path() -> String:
	# Always return a valid path; updates cache when possible
	var s = get_tree().current_scene
	if s:
		_last_known_scene_path = s.scene_file_path
		return _last_known_scene_path
	return _last_known_scene_path

func goto_scene(path):
	_deferred_goto_scene.call_deferred(path)

func reload_scene():
	# Avoid reload_current_scene(); it can leave current_scene transiently invalid.
	goto_scene(get_current_scene_path())

func reload_from_checkpoint():
	PlayerVariables.current_health = PlayerVariables.max_health
	goto_scene(CheckpointManager._scene_path)

func _deferred_goto_scene(path):
	var old = current_scene

	var s = ResourceLoader.load(path)
	var inst = s.instantiate()

	get_tree().root.add_child(inst)
	get_tree().current_scene = inst
	current_scene = inst
	_last_known_scene_path = path  # keep cache fresh immediately

	if is_instance_valid(old):
		old.queue_free()
