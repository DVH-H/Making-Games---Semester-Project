extends Node2D


@export var player: CharacterBody2D

func _ready() -> void:
	for child in player.get_children():
		if child.name == "CanvasLayer":
			child.visible = false
	
