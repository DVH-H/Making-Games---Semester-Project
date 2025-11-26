extends enemy

var debris_scene = preload("res://enemy/debris.tscn")


func AGGRO_behaviour() -> float:
	if in_attack_range and attack_cd_ready:
		state = ATTACK
	return 0
	
	
func ATTACK_behaviour(_delta):
	if player and player_chase and attack_cd_ready:
		animation_node.play("attack")
		var debris := debris_scene.instantiate()
		get_tree().root.add_child(debris)
		debris.global_position = global_position
		debris.initialize(player.global_position.x, damage)
		attack_cd_ready = false
		#state = AGGRO
	return 0
	
