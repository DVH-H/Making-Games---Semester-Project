extends Node


# Checkpoint
var _scene_path: String = "res://game.tscn"
var _spawn_coords: Vector2

func set_checkpoint(scene, coords):
	_scene_path = GameController.current_scene.scene_file_path
	_spawn_coords = coords

func spawn_player_at_checkpoint(player: CharacterBody2D):
	if _spawn_coords != Vector2.ZERO:
		player.global_position = _spawn_coords
