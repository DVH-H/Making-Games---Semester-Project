extends Node2D

@onready var image_list 
@onready var timer = $Timer
@export var next_scene: PackedScene
@export var list_of_images: Array[Texture]
@export var timer_length: float = 1
@export var player: CharacterBody2D
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
		image_list = $CanvasLayer.get_children()
		timer.wait_time = timer_length
		timer.start()
		timer.timeout.connect(_on_timer)
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
		GameController.goto_scene(next_scene.resource_path)
		get_tree().paused = false
	else:
		image_list[index].visible = true
