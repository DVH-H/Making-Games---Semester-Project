extends Node2D


@export var player: CharacterBody2D
@export var level_1: PackedScene
@onready var play_button: TextureButton = $CanvasLayer/Control/MarginContainer/HBoxContainer/VBoxContainer/playButton



func _ready() -> void:
	play_button.pressed.connect(_load_level)
	for child in player.get_children():
		if child.name == "CanvasLayer":
			child.visible = false
	player.set_process(false)
	player.set_physics_process(false)
	
	
func _load_level():
	CheckpointManager.set_checkpoint(level_1.resource_path, Vector2.ZERO)
	GameController.goto_scene(level_1.resource_path)
