extends Camera2D


@onready var player = get_tree().current_scene.get_node("Player")
@export var speed = 5
@export var delay = 1
@export var length = 1500
var delay_timer = 0.0
var use_velocity: bool = true
var player_velocity: Vector2
var direction: float


func _process(delta: float) -> void:
	if get_tree().current_scene.name == "MainMenu":
		return
	var player_pos
	if player:
		player_pos = player.position + Vector2(0, -1000)
	else:
		player = get_tree().current_scene.get_node("Player")
		player_pos = player.position + Vector2(0, -1000)
		position = player_pos
	var mouse_pos: Vector2 = get_global_mouse_position()
	var aim_dir = (mouse_pos - global_position).normalized()
	if player.velocity == Vector2.ZERO:
		delay_timer += delta
		if delay_timer > delay:
			use_velocity = false
	else:
		player_velocity = player.velocity
		use_velocity = true
		delay_timer = 0.0
	var new_pos
	var target_pos = player_pos
	var current_speed = speed
	if use_velocity:
		target_pos.x = player_pos.x + (player_velocity.normalized().x * length)
		if position.distance_to(target_pos) > 500:
			current_speed *= 5
	else:
		current_speed *= 2
		target_pos = player_pos + (aim_dir * length)
		#new_pos = position.lerp(, speed * delta * 2)
	new_pos = position.lerp(target_pos, current_speed * delta)
	position = new_pos
