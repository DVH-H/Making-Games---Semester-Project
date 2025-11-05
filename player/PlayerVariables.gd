extends Node




@export var default_max_health: int = 100
var current_health = default_max_health

@export_subgroup("Movement")
@export var default_speed: int = 100
@export var default_jump_velocity: int = 350
@export var default_coyote_time = 0.2

var speed: int = default_speed
var jump_velocity: int = default_jump_velocity
var coyote_tine: int = default_coyote_time
