extends CanvasLayer

@onready var play_button: TextureButton = $Control/MarginContainer/HBoxContainer/VBoxContainer/playButton
@onready var controls_button: TextureButton = $Control/MarginContainer/HBoxContainer/VBoxContainer/ControlsButton
@onready var quit_button: TextureButton = $Control/MarginContainer/HBoxContainer/VBoxContainer/quitButton


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("reset"):
		get_tree().paused = not get_tree().paused
		visible = not visible
		

func _ready() -> void:
	play_button.pressed.connect(_press_play)
	controls_button.pressed.connect(_press_controls)
	quit_button.pressed.connect(_press_quit)
	
	
func _press_play():
	visible = false
	get_tree().paused = false
	
func _press_controls():
	pass
	
func _press_quit():
	get_tree().quit(0)
