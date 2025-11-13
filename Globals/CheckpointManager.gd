extends Node


# Checkpoint
var _scene_path: String = "res://game.tscn"
var _spawn_coords: Vector2

func set_checkpoint(scene, coords):
	_scene_path = GameController.get_current_scene_path()
	_spawn_coords = coords

func spawn_player_at_checkpoint(player: CharacterBody2D):
	if _spawn_coords != Vector2.ZERO:
		player.global_position = _spawn_coords

func has_checkpoint() -> bool:
	return _spawn_coords != Vector2.ZERO or _scene_path != "res://game.tscn"

func clear_checkpoint():
	_spawn_coords = Vector2.ZERO
	_scene_path = "res://game.tscn"
