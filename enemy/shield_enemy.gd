extends enemy

@onready var shield: Node2D = $Shield
var attack_direction: int = 0
@export var attack_dash_speed_multiplier: float = 2



func aim_shield() -> void:
	if state == AGGRO:
		shield.look_at(global_position + (player.global_position - global_position).normalized())
		var rd = shield.rotation_degrees
		rd = wrap(rd, 0, 360)
		shield.rotation_degrees = rd
		shield.scale.y = -1 if rd > 90 and rd < 270 else 1
	else:
		shield.look_at(global_position + (dir))
		
func AGGRO_behaviour() -> float:
	if player and player_chase:
		aim_shield()
		var direction = 0
		if is_at_edge(direction) and is_on_floor():
			movement_component.handle_jump(self)
		if player.position.x > position.x:
			attack_area_direction(1)
			if player.position.x - 2000 > position.x:
				direction = 1
			elif player.position.x - 1000 < position.x:
				direction = -1
		else:
			attack_area_direction(-1)
			if player.position.x + 2000 < position.x:
				direction = -1
			elif  player.position.x + 1000 > position.x:
				direction = 1
		if in_attack_range and attack_cd_ready:
			state = ATTACK
			if player.position.x > position.x:
				attack_direction = 1
			else:
				attack_direction = -1
		return direction
	return 0
	
func ATTACK_behaviour():
	attack_timer.start()
	attack_cd_ready = false
	animation_node.play("attack")
	movement_component.set_speed(speed * 2)
	return attack_direction

func _on_animated_sprite_2d_animation_finished() -> void:
	super()
	if animation_node.animation == "attack":
		movement_component.set_speed(speed)

func _on_attack_area_body_entered(body: Node2D) -> void:
	super(body)
	if player.position.x > position.x:
		attack_direction = 1
	else:
		attack_direction = -1
	
