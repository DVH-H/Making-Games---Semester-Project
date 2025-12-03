# File: canvas_layer.gd (HUD)
extends CanvasLayer

@export var player_path: NodePath
@export var gun_path: NodePath

@onready var player: Node = get_node(player_path)
@onready var gun: Gun = get_node(gun_path)
@onready var wheel: RevolverCylinderUI = $RevolverCylinderUI
@onready var reload_bar: ReloadBarControl = $ReloadBar   # keep your node name
@onready var health_ui = $HealthUI

func _ready() -> void:
	if gun == null:
		push_error("HUD: gun_path is not set or node not found")
		return

	# Sync RevolverCylinderUI capacity with gun capacity
	if wheel:
		wheel.capacity = gun.capacity
		print("HUD: Synced wheel capacity to gun capacity: ", gun.capacity)

	# --- Initial sync ---
	_on_chamber_changed(gun.current_index)

	# States from chambers
	var states: Array[bool] = []
	for i in gun.capacity:
		states.append(gun.chambers[i] != null)
	_on_chambers_updated(states)

	if gun.has_method("get_chamber_colors"):
		_on_chamber_colors_updated(gun.get_chamber_colors())
	
	if gun.has_method("_icons_from"):
		_on_chamber_icons_updated(gun._icons_from(gun.chambers))

	# --- Signals -> UI ---
	gun.chamber_changed.connect(_on_chamber_changed)
	gun.chambers_updated.connect(_on_chambers_updated)
	if gun.has_signal("chamber_colors_updated"):
		gun.chamber_colors_updated.connect(_on_chamber_colors_updated)
	if gun.has_signal("chamber_icons_updated"):
		gun.chamber_icons_updated.connect(_on_chamber_icons_updated)
	
	# Connect player health signals
	if player and player.has_signal("health_changed"):
		print("HUD: Connecting to player health_changed signal")
		player.health_changed.connect(_on_health_changed)
		if not health_ui:
			push_error("HUD: health_ui node not found!")
	else:
		push_error("HUD: player node not found or doesn't have health_changed signal")

func _on_chamber_changed(idx: int) -> void:
	wheel.set_current_index(idx)

func _on_chambers_updated(states: Array[bool]) -> void:
	wheel.set_chambers(states)

func _on_chamber_colors_updated(colors: Array[Color]) -> void:
	wheel.set_chamber_colors(colors)

func _on_chamber_icons_updated(icons: Array[Texture2D]) -> void:
	wheel.set_chamber_icons(icons)

func _on_health_changed(new_health: int, max_health_value: int) -> void:
	if health_ui:
		# First time, set max health
		if health_ui.max_health != max_health_value:
			print("HUD: Initializing health UI with max_health=", max_health_value)
			health_ui.set_max_health(max_health_value)
		print("HUD: Updating health to ", new_health)
		health_ui.set_health(new_health)
