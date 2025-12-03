# File: RevolverCylinderUI.gd
@tool
extends Control
class_name RevolverCylinderUI

## --- Exposed properties ---
@export_range(1, 12, 1) var capacity: int = 6 : set = _set_capacity
@export_range(0, 11, 1) var current_index: int = 0 : set = _set_current_index
@export var clockwise: bool = true : set = _set_clockwise

@export_group("Image Mode")
@export var cylinder_background: Texture2D
@export var background_scale: float = 1.0 : set = _set_background_scale
@export var bullet_scale: float = 0.17

@export_group("Visual Tuning")
@export var outer_radius: float = 16.0 : set = _set_outer_radius
@export var gap_from_edge: float = 3.0 : set = _set_gap_from_edge

## Data inputs from game
var chamber_states: Array[bool] = [] : set = _set_chamber_states
var chamber_colors: Array[Color] = [] : set = _set_chamber_colors  # aligns with capacity when used
var chamber_icons: Array[Texture2D] = [] : set = _set_chamber_icons  # bullet icons

func set_current_index(idx: int) -> void: _set_current_index(idx)
func set_chambers(states: Array[bool]) -> void: _set_chamber_states(states)
func set_chamber_colors(colors: Array[Color]) -> void: _set_chamber_colors(colors)
func set_chamber_icons(icons: Array[Texture2D]) -> void: _set_chamber_icons(icons)

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	if capacity <= 0:
		return
	_draw_image_mode()


func _draw_image_mode() -> void:
	var center := size * 0.5
	
	# Draw cylinder background image if available
	if cylinder_background:
		var tex_size := cylinder_background.get_size() * background_scale
		var draw_pos := center - tex_size * 0.5
		draw_texture_rect(cylinder_background, Rect2(draw_pos, tex_size), false)
	
	# Now draw chambers using same logic as classic mode
	var big_r := outer_radius
	var step := TAU / float(capacity)
	var base_angle := -PI * 0.5
	var dir := 1.0 if clockwise else -1.0
	
	# States
	var states: Array[bool] = chamber_states.duplicate()
	
	
	# Draw chambers - use icons if available, otherwise colored circles
	var first = true
	for i in capacity:
		var chamber_idx := posmod(current_index + int(dir) * i, capacity)
		var angle := base_angle + dir * (step * i)
		var pos := center + Vector2(cos(angle), sin(angle)) * (big_r - gap_from_edge)
		var filled := states[chamber_idx]
		
		# Check if we have an icon for this chamber
		var icon: Texture2D = null
		if filled and chamber_icons.size() == capacity:
			icon = chamber_icons[chamber_idx]
		
		# Draw current chamber (i==0) duplicate at center of screen
		if first:
			first = false
			var screen_center := get_viewport().get_visible_rect().size / 2
			print(get_viewport().get_visible_rect())
			if icon:
				var icon_size := icon.get_size() * bullet_scale
				var icon_pos := screen_center - icon_size * 0.5
				draw_texture_rect(icon, Rect2(icon_pos, icon_size), false)
		
		if icon:
			# Draw icon
			var icon_size := icon.get_size() * bullet_scale
			var icon_pos := pos - icon_size * 0.5
			draw_texture_rect(icon, Rect2(icon_pos, icon_size), false)

# --- Setters that actually store values (so Inspector works) ---
func _set_capacity(v: int) -> void:
	capacity = max(1, v)
	if not chamber_states.is_empty():
		var s: Array[bool] = []
		for i in capacity: s.append(i < chamber_states.size() and bool(chamber_states[i]))
		chamber_states = s
	queue_redraw()

func _set_current_index(v: int) -> void:
	current_index = posmod(v, max(1, capacity))
	queue_redraw()

func _set_clockwise(v: bool) -> void:
	clockwise = v
	queue_redraw()

func _set_outer_radius(v: float) -> void:
	outer_radius = v
	queue_redraw()

func _set_gap_from_edge(v: float) -> void:
	gap_from_edge = v
	queue_redraw()

func _set_background_scale(v: float) -> void:
	background_scale = v
	queue_redraw()

func _set_chamber_states(states: Array[bool]) -> void:
	chamber_states = states.duplicate()
	queue_redraw()

func _set_chamber_colors(colors: Array[Color]) -> void:
	chamber_colors = colors.duplicate()
	queue_redraw()

func _set_chamber_icons(icons: Array[Texture2D]) -> void:
	chamber_icons = icons.duplicate()
	queue_redraw()
