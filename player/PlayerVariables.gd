extends Node




@export var max_health: int = 100
@onready var current_health: int = max_health

@export_subgroup("Movement")

@export var speed: int = 100
@export var jump_velocity: int = 350
@export var velocity_cap: int = 500
@export var coyote_time: float = 0.2

# Avilable bullets:
var normal_round: PackedScene = preload("res://Bullets/prefabs/bullet.tscn")
var knockback_round: PackedScene = preload("res://Bullets/prefabs/knockback_bullet.tscn")
var explosive_round: PackedScene = preload("res://Bullets/prefabs/explosive_bullet.tscn")
var triple_round: PackedScene = preload("res://Bullets/prefabs/triple_bullet.tscn")

@onready var default_loadout: Array[PackedScene] = [knockback_round, knockback_round, knockback_round, explosive_round, explosive_round, triple_round]
