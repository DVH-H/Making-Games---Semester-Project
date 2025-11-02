# File: canvas_layer.gd (HUD)
extends CanvasLayer

@export var player_path: NodePath
@export var gun_path: NodePath

@onready var player: Node = get_node(player_path)
@onready var gun: Gun = get_node(gun_path)               # e.g. "../Player/Gun" from the CanvasLayer
@onready var wheel: RevolverCylinderUI = $RevolverCylinderUI
@onready var reload_bar: ReloadBarControl = $ReloadBar

func _ready() -> void:
	# Initial sync
	if gun:
		_on_ammo_changed(gun.get_ammo_count())
		_on_chamber_changed(gun.current_index)

		# Build initial states/colors from gun (assumes gun exposes these public arrays)
		var states: Array[bool] = []
		for i in gun.capacity:
			states.append(gun.chambers[i] != null)
		_on_chambers_updated(states)
		if gun.colors:
			_on_chamber_colors_updated(gun.colors)

		# Signals -> UI
		gun.ammo_changed.connect(_on_ammo_changed)
		gun.chamber_changed.connect(_on_chamber_changed)
		gun.chambers_updated.connect(_on_chambers_updated)
		if gun.has_signal("chamber_colors_updated"):
			gun.chamber_colors_updated.connect(_on_chamber_colors_updated)

	# Optional: click-to-set next chamber
	wheel.chamber_clicked.connect(_on_wheel_clicked)

	# Reload progress bar already connects directly to gun inside its own script
	# (via exported gun_path), so no extra wiring is necessary here.

func _on_ammo_changed(a: int) -> void:
	wheel.set_ammo_count(a)

func _on_chamber_changed(idx: int) -> void:
	wheel.set_current_index(idx)

func _on_chambers_updated(states: Array[bool]) -> void:
	wheel.set_chambers(states)

func _on_chamber_colors_updated(colors: Array[Color]) -> void:
	wheel.set_chamber_colors(colors)

func _on_wheel_clicked(idx: int) -> void:
	if gun:
		gun.current_index = idx
		_on_chamber_changed(idx)
