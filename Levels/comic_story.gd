extends Node2D

@onready var image_list = $CanvasLayer.get_children()
@onready var timer = $Timer
@export var next_scene: PackedScene
@onready var player: CharacterBody2D = $Player
var index = 0

func _ready() -> void:
	timer.timeout.connect(_on_timer)
	get_tree().paused = true
	for child in player.get_children():
		if child.name == "CanvasLayer":
			child.visible = false


func _on_timer():
	image_list[index].visible = false
	index += 1
	if index == len(image_list):
		GameController.goto_scene(next_scene.resource_path)
		get_tree().paused = false
	else:
		image_list[index].visible = true
