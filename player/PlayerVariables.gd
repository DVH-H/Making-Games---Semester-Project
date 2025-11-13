extends Node




@export var max_health: int = 100
@onready var current_health: int = max_health

@export_subgroup("Movement")

@export var speed: int = 100
@export var jump_velocity: int = 350
@export var velocity_cap: int = 500
@export var coyote_time: float = 0.2
