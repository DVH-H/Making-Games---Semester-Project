extends Node2D

@onready var image_list 
@onready var timer = $Timer
var next_scene: PackedScene
@export var list_of_images: Array[Texture]
@export var timer_lengths: Array[float]
@export var player: CharacterBody2D
@export var soundFile: AudioStreamPlayer
var index = 0

func _ready() -> void:
	if len(list_of_images) > 0:
		for img in list_of_images:
			var tRect = TextureRect.new()
			tRect.texture = img
			tRect.visible = false
			tRect.set_anchors_preset(Control.PRESET_FULL_RECT)
			$CanvasLayer.add_child(tRect)
		$CanvasLayer.get_children()[0].visible = true
		$SoundComponent.play_sound(soundFile)
		image_list = $CanvasLayer.get_children()
		timer.wait_time = timer_lengths[0]
		timer.start()
		timer.timeout.connect(_on_timer)
		Camera.position_smoothing_enabled = false
		Camera.position = Vector2.ZERO
		Menu.ui_disabled = true
		get_tree().paused = true
		for child in player.get_children():
			if child.name == "CanvasLayer":
				child.visible = false
	else:
		GameController.goto_scene(next_scene.resource_path)


func _on_timer():
	image_list[index].visible = false
	index += 1
	if index == len(image_list):
		if get_tree().current_scene.name == "EndScene":
			next_scene = load("res://Levels/MainMenu.tscn")
		else:
			next_scene = load("res://levels/Level_industrial1.tscn")
		CheckpointManager.set_checkpoint(next_scene.resource_path, Vector2.ZERO)
		GameController.goto_scene(next_scene.resource_path)
		get_tree().paused = false
		Camera.position_smoothing_enabled = true
		Menu.ui_disabled = false
	else:
		image_list[index].visible = true
		timer.wait_time = timer_lengths[index]
		timer.start()
