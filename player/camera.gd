extends Camera2D


@onready var player = get_tree().current_scene.get_node("Player")
@export var speed = 5
@export var delay = 1
@export var length = 1500
var delay_timer = 0.0
var use_velocity: bool = true
var player_velocity: Vector2


func _process(delta: float) -> void:
	var player_pos = player.position + Vector2(0, -1000)
	var mouse_pos: Vector2 = get_global_mouse_position()
	var aim_dir = (mouse_pos - global_position).normalized()
	#if not player.velocity == Vector2.ZERO: 
	if player.velocity == Vector2.ZERO:
		delay_timer += delta
		if delay_timer > delay:
			use_velocity = false
	else:
		player_velocity = player.velocity
		use_velocity = true
		delay_timer = 0.0
	var new_pos
	if use_velocity:
		new_pos = position.lerp(player_pos + (player_velocity.normalized() * length), speed * delta)
	else:
		new_pos = position.lerp(player_pos + (aim_dir * length), speed * delta * 2)
	position = new_pos
