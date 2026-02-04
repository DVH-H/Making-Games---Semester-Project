extends Node


# Checkpoint
var _default_scene_path: String = "res://levels/Level_industrial1.tscn"
var _scene_path: String = "res://levels/Level_industrial1.tscn"
var _spawn_coords: Vector2
var _respawn_at_checkpoint: bool = false

func set_checkpoint(scene, coords):
	_scene_path = scene
	_spawn_coords = coords

func spawn_player_at_checkpoint(player: CharacterBody2D):
	if _respawn_at_checkpoint and _spawn_coords != Vector2.ZERO:
		_respawn_at_checkpoint = false
		player.global_position = _spawn_coords

func has_checkpoint() -> bool:
	return _spawn_coords != Vector2.ZERO or _scene_path != _default_scene_path

func clear_checkpoint():
	_spawn_coords = Vector2.ZERO
	_scene_path = _default_scene_path
