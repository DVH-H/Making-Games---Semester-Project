# File: LoadoutManager.gd
# Global autoload for managing gun loadouts
extends Node

# Available bullet types
var available_bullets: Array[PackedScene] = []
var bullet_instances: Dictionary = {}  # path -> Bullet instance for UI info

# Current loadout (what the player has configured)
var current_loadout: Array[PackedScene] = []
var loadout_capacity: int = 6

signal loadout_changed(new_loadout: Array[PackedScene])

func _ready() -> void:
	_initialize_bullet_types()
	_set_default_loadout()

func _initialize_bullet_types() -> void:
	# Register available bullet types
	var normal_bullet = preload("res://Bullets/prefabs/bullet.tscn")
	var knockback_bullet = preload("res://Bullets/prefabs/knockback_bullet.tscn")
	
	available_bullets = [normal_bullet, knockback_bullet]
	
	# Cache bullet instances for UI info access
	for bullet_scene in available_bullets:
		var bullet_instance = bullet_scene.instantiate()
		if bullet_instance is Bullet:
			bullet_instances[bullet_scene.resource_path] = bullet_instance
		else:
			push_error("LoadoutManager: Scene does not contain a Bullet instance: " + bullet_scene.resource_path)
			bullet_instance.queue_free()

func _set_default_loadout() -> void:
	current_loadout.clear()
	current_loadout.resize(loadout_capacity)
	
	# Default alternating pattern
	for i in loadout_capacity:
		current_loadout[i] = available_bullets[0] if (i % 2) == 0 else available_bullets[1]

func get_loadout() -> Array[PackedScene]:
	return current_loadout.duplicate()

func set_loadout(new_loadout: Array[PackedScene]) -> void:
	if new_loadout.size() != loadout_capacity:
		push_error("LoadoutManager: Invalid loadout size. Expected %d, got %d" % [loadout_capacity, new_loadout.size()])
		return
	
	current_loadout = new_loadout.duplicate()
	emit_signal("loadout_changed", current_loadout)

func set_bullet_at_index(index: int, bullet_scene: PackedScene) -> void:
	if index < 0 or index >= loadout_capacity:
		push_error("LoadoutManager: Invalid chamber index %d" % index)
		return
	
	current_loadout[index] = bullet_scene
	emit_signal("loadout_changed", current_loadout)

func get_bullet_at_index(index: int) -> PackedScene:
	if index < 0 or index >= loadout_capacity:
		return null
	return current_loadout[index]

func get_available_bullets() -> Array[PackedScene]:
	return available_bullets.duplicate()

func get_bullet_info(bullet_scene: PackedScene) -> Bullet:
	if bullet_scene == null:
		return null
	return bullet_instances.get(bullet_scene.resource_path, null)

func set_capacity(new_capacity: int) -> void:
	if new_capacity < 1 or new_capacity > 12:
		push_error("LoadoutManager: Invalid capacity %d. Must be 1-12" % new_capacity)
		return
	
	var old_loadout = current_loadout.duplicate()
	loadout_capacity = new_capacity
	current_loadout.resize(loadout_capacity)
	
	# Fill new slots with default bullets if expanding
	for i in range(old_loadout.size(), loadout_capacity):
		current_loadout[i] = available_bullets[0]  # Default to normal bullet
	
	emit_signal("loadout_changed", current_loadout)
